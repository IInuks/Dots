#!/usr/bin/env bash
# Assigns an app launcher to a bar (the "Launcher" tab in the menu). The
# assignment is saved in ~/.local/state/quickdots/launchers.json and stays
# until it's changed again -- switch-bar.sh picks it up whenever that bar
# becomes active. If <bar> is the active bar right now, it takes effect
# immediately: launcher host started/stopped, SUPER+space rebound.
#
# Usage: set-launcher.sh <bar> <launcher>
#   <launcher> = a bar name (its launcher), "appsearch" (the menu's app
#   search) or "default" (the bar's own launcher, else the app search)
#
# Prints one line per completed step, matching LauncherStore.qml's
# stepLabels exactly:
#   Zuweisung gespeichert
#   Launcher gestartet
#   Keybinds aktualisiert

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MENU_DIR="$ROOT/menu"
STATE_FILE="$HOME/.local/state/quickdots/active-bar"

BAR="${1:?usage: set-launcher.sh <bar> <launcher>}"
LAUNCHER="${2:?usage: set-launcher.sh <bar> <launcher>}"

"$MENU_DIR/scripts/launchers.py" set "$BAR" "$LAUNCHER"
echo "Zuweisung gespeichert"

if [ "$(cat "$STATE_FILE" 2>/dev/null || true)" = "$BAR" ]; then
    "$MENU_DIR/scripts/launcher-host.sh" sync
    echo "Launcher gestartet"
    "$MENU_DIR/scripts/mango-block.sh" "$BAR"
    echo "Keybinds aktualisiert"
fi
