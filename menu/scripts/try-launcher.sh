#!/usr/bin/env bash
# "Ausprobieren" in the menu's Launcher tab: opens a bar's launcher right
# now without assigning it. The active bar's own launcher opens through
# that bar's SUPER+space command (adapters/<bar>.json); any other runs
# through its host (launcher-host.sh run -- the assigned host keeps
# running). The menu's next open syncs the hosts again, which stops one
# that was only started for this.
#
# Usage: try-launcher.sh <bar>

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MENU_DIR="$ROOT/menu"
BARS_DIR="$ROOT/bars"
STATE_FILE="$HOME/.local/state/quickdots/active-bar"

BAR="${1:?usage: try-launcher.sh <bar>}"

if [ "$(cat "$STATE_FILE" 2>/dev/null || true)" = "$BAR" ]; then
    CMD="$(python3 -c '
import json, re, sys
try:
    binds = json.load(open(sys.argv[1])).get("keybinds", [])
except Exception:
    binds = []
for b in binds:
    m = re.match(r"^\s*bind\s*=\s*SUPER\s*,\s*space\s*,\s*spawn\s*,(.*)$", b, re.I)
    if m:
        print(m.group(1).strip())
        break
' "$MENU_DIR/adapters/$BAR.json")"
    [ -n "$CMD" ] && exec sh -c "$CMD"
    echo "Fehler: kein SUPER+space-Bind in adapters/$BAR.json" >&2
    exit 1
fi

HOST="$BARS_DIR/$BAR/.quickdots-launcher.qml"
"$MENU_DIR/scripts/launcher-host.sh" run "$BAR"
# Wait (max. ~6 s) until the host answers on IPC -- a fresh start loads the
# bar's singletons first.
for _ in $(seq 30); do
    if qs -p "$HOST" ipc show >/dev/null 2>&1; then
        exec qs -p "$HOST" ipc call launcher toggle
    fi
    sleep 0.2
done
echo "Fehler: Launcher-Host für „$BAR“ antwortet nicht" >&2
exit 1
