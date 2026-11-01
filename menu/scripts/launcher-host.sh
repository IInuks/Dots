#!/usr/bin/env bash
# Runs another bar's launcher on its own, without that bar: copies
# menu/launchers/hosts/<bar>.qml into bars/<bar>/.quickdots-launcher.qml
# (it has to live next to the bar's own files to see its types and
# singletons) and starts it as a separate quickshell instance. The copy
# gets the bar's own shell id, so the launcher reads the same settings and
# theme state as the bar itself.
#
# Usage:
#   launcher-host.sh sync          make the running host match the active
#                                  bar's launcher (start/stop as needed)
#   launcher-host.sh start <bar>   (re)generate + start <bar>'s host, stop others
#   launcher-host.sh run <bar>     same, but leave other hosts running
#                                  (try-launcher.sh: the assigned one stays)
#   launcher-host.sh stop          stop every running host
#
# Like switch-bar.sh, only ever kills instances by their exact config path
# (never pkill) -- the menu and the bars are quickshell instances too.

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MENU_DIR="$ROOT/menu"
BARS_DIR="$ROOT/bars"
HOST_FILE=".quickdots-launcher.qml"
STATE_FILE="$HOME/.local/state/quickdots/active-bar"

# PIDs of running hosts, optionally all but the one for bar $1.
host_pids() {
    qs list --all --json 2>/dev/null | python3 -c '
import json, sys
bars, host, keep = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for inst in data:
    p = inst.get("config_path", "")
    if p.startswith(bars + "/") and p.endswith("/" + host):
        if keep and p == bars + "/" + keep + "/" + host:
            continue
        print(inst["pid"])
' "$BARS_DIR" "$HOST_FILE" "${1:-}" || true
}

stop_hosts() {
    local pid
    for pid in $(host_pids "${1:-}"); do
        # Frozen instances never answer `qs kill` (IPC) -- escalate.
        timeout 2 qs kill --pid "$pid" >/dev/null 2>&1 || true
        sleep 0.3
        kill -0 "$pid" 2>/dev/null && kill -TERM "$pid" 2>/dev/null && sleep 0.5
        kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
    done
}

start_host() {
    local bar="$1"
    local src="$MENU_DIR/launchers/hosts/$bar.qml"
    local dst="$BARS_DIR/$bar/$HOST_FILE"
    if [ ! -f "$src" ] || [ ! -f "$BARS_DIR/$bar/shell.qml" ]; then
        echo "Fehler: kein Launcher-Host für „$bar“ ($src)" >&2
        return 1
    fi
    local shell_id
    shell_id="$(printf '%s' "$BARS_DIR/$bar/shell.qml" | md5sum | cut -d' ' -f1)"
    # Only rewrite on change: a running host would hot-reload on every write.
    local tmp="$dst.tmp"
    { echo "//@ pragma ShellId $shell_id"; cat "$src"; } > "$tmp"
    if cmp -s "$tmp" "$dst"; then rm -f "$tmp"; else mv "$tmp" "$dst"; fi
    # -n: no-op if this host already runs.
    setsid qs -p "$dst" -n >/dev/null 2>&1 < /dev/null &
    disown
}

case "${1:-}" in
    sync)
        bar="$(cat "$STATE_FILE" 2>/dev/null || true)"
        read -r mode launcher < <("$MENU_DIR/scripts/launchers.py" resolve "${bar:-_}")
        if [ -n "$bar" ] && [ "$mode" = "host" ]; then
            stop_hosts "$launcher"
            start_host "$launcher"
        else
            stop_hosts
        fi
        ;;
    start)
        bar="${2:?usage: launcher-host.sh start <bar>}"
        stop_hosts "$bar"
        start_host "$bar"
        ;;
    run)
        start_host "${2:?usage: launcher-host.sh run <bar>}"
        ;;
    stop)
        stop_hosts
        ;;
    *)
        echo "usage: launcher-host.sh sync | start <bar> | run <bar> | stop" >&2
        exit 2
        ;;
esac
