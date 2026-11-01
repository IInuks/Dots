#!/usr/bin/env bash
# Runs salbei's desktop widgets on their own (bars/salbei/widgets.qml) while
# another bar is active, so the "Widgets" tab works with every bar. salbei
# itself already has the widgets, so the host never runs next to it.
#
# Usage:
#   widgets-host.sh sync   start the host unless salbei is the active bar,
#                          stop it if it is
#   widgets-host.sh stop   stop the host
#
# Like switch-bar.sh, only ever kills the instance by its exact config path
# (never pkill) -- the menu and the bars are quickshell instances too.

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
HOST="$ROOT/bars/salbei/widgets.qml"
STATE_FILE="$HOME/.local/state/quickdots/active-bar"

stop_host() {
    local pid
    for pid in $(qs list --all --json 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for inst in data:
    if inst.get("config_path") == sys.argv[1]:
        print(inst["pid"])
' "$HOST" || true); do
        # Frozen instances never answer `qs kill` (IPC) -- escalate.
        timeout 2 qs kill --pid "$pid" >/dev/null 2>&1 || true
        sleep 0.3
        kill -0 "$pid" 2>/dev/null && kill -TERM "$pid" 2>/dev/null && sleep 0.5
        kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
    done
}

case "${1:-}" in
    sync)
        bar="$(cat "$STATE_FILE" 2>/dev/null || true)"
        if [ "$bar" = "salbei" ]; then
            stop_host
        else
            # -n: no-op if the host already runs.
            setsid qs -p "$HOST" -n >/dev/null 2>&1 < /dev/null &
            disown
        fi
        ;;
    stop)
        stop_host
        ;;
    *)
        echo "usage: widgets-host.sh sync | stop" >&2
        exit 2
        ;;
esac
