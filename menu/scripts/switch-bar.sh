#!/usr/bin/env bash
# Switches the active Quickshell bar: kills only the old bar's own PID
# (never a blanket pkill -- this menu is its own long-running quickshell
# instance and must survive), starts the new one plus the launcher assigned
# to it (launcher-host.sh, if it uses another bar's launcher) and salbei's
# desktop widgets (widgets-host.sh, unless the new bar is salbei), persists the
# choice, rewrites the quickdots block in mango's config (mango-block.sh),
# and reloads it live.
#
# Usage: switch-bar.sh <bar-folder-name>
#
# Prints one line per completed step, matching SwitchState.qml's
# stepLabels exactly, so the menu's status list can tick them off live:
#   Alte Bar beenden
#   Neue Bar starten
#   Config angepasst
#   Keybinds aktualisiert

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MENU_DIR="$ROOT/menu"
BARS_DIR="$ROOT/bars"
STATE_DIR="$HOME/.local/state/quickdots"
STATE_FILE="$STATE_DIR/active-bar"

NEW_BAR="${1:?usage: switch-bar.sh <bar-name>}"
NEW_BAR_PATH="$BARS_DIR/$NEW_BAR"

if [ ! -f "$NEW_BAR_PATH/shell.qml" ]; then
    echo "Fehler: $NEW_BAR_PATH/shell.qml nicht gefunden" >&2
    exit 1
fi

mkdir -p "$STATE_DIR"
OLD_BAR="$(cat "$STATE_FILE" 2>/dev/null || true)"

# --- Step 1: alte Bar beenden -------------------------------------------
echo "Alte Bar beenden"
if [ -n "$OLD_BAR" ] && [ "$OLD_BAR" != "$NEW_BAR" ]; then
    OLD_BAR_PATH="$BARS_DIR/$OLD_BAR"
    OLD_PID="$(qs list --all --json 2>/dev/null | python3 -c '
import json, sys
target = sys.argv[1]
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for inst in data:
    if inst.get("config_path") == target:
        print(inst["pid"])
        break
' "$OLD_BAR_PATH/shell.qml" || true)"

    if [ -n "$OLD_PID" ]; then
        # `qs kill` asks over IPC -- a frozen (deadlocked) bar never answers
        # and kept sitting on top of the new one. Escalate to TERM, then KILL.
        timeout 2 qs kill --pid "$OLD_PID" >/dev/null 2>&1 || true
        for sig in TERM KILL; do
            for _ in 1 2 3 4 5 6 7 8 9 10; do
                kill -0 "$OLD_PID" 2>/dev/null || break 2
                sleep 0.1
            done
            kill -"$sig" "$OLD_PID" 2>/dev/null || true
        done
    fi
fi

# --- Step 2: neue Bar starten --------------------------------------------
echo "Neue Bar starten"
# Hosts first: a host for the new bar's own launcher (left over from a bar
# that borrowed it) would otherwise run next to the bar itself.
"$MENU_DIR/scripts/launcher-host.sh" stop
# -n: exits immediately (no-op) if this config is already running, which
# makes re-running this script for the already-active bar safe/idempotent.
setsid qs -p "$NEW_BAR_PATH" -n >/dev/null 2>&1 < /dev/null &
disown
echo "$NEW_BAR" > "$STATE_FILE"
# The launcher assigned to the new bar (no-op for its own / the app search).
"$MENU_DIR/scripts/launcher-host.sh" sync
# salbei's desktop widgets for every other bar (salbei has its own).
"$MENU_DIR/scripts/widgets-host.sh" sync

# --- Step 3+4: mango-Config-Block neu schreiben + Keybinds ---------------
echo "Config angepasst"
"$MENU_DIR/scripts/mango-block.sh" "$NEW_BAR"
echo "Keybinds aktualisiert"
