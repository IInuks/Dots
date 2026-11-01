#!/usr/bin/env bash
# Rewrites the block between "# >>> quickdots >>>" and "# <<< quickdots <<<"
# in mango's config.conf for <bar> (backup first, rest of the file stays
# untouched), then reloads mango. Shared by switch-bar.sh and
# set-launcher.sh.
#
# Usage: mango-block.sh <bar-folder-name>
#
# The block: autostart of the menu, the bar and its launcher host (if it
# uses another bar's launcher, see launcher-host.sh), salbei's desktop
# widgets for other bars (widgets-host.sh), the menu keybind, and
# the bar's keybinds from adapters/<bar>.json -- with SUPER+space pointing
# at whichever launcher is assigned to the bar (launchers.py keybinds).

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MENU_DIR="$ROOT/menu"
BARS_DIR="$ROOT/bars"
MANGO_CONF="${MANGO_CONF:-$HOME/.config/mango/config.conf}"

BAR="${1:?usage: mango-block.sh <bar-name>}"
MODE="${2:-all}"
case "$MODE" in all|autostart) ;; *) echo "usage: mango-block.sh <bar-name> [all|autostart]" >&2; exit 2 ;; esac

KEYBINDS=""
if [[ "$MODE" == all ]]; then KEYBINDS="$("$MENU_DIR/scripts/launchers.py" keybinds "$BAR")"; fi

BLOCK="exec-once=qs -p $MENU_DIR -n &
exec-once=qs -p $BARS_DIR/$BAR -n &
exec-once=$MENU_DIR/scripts/launcher-host.sh sync
exec-once=$MENU_DIR/scripts/widgets-host.sh sync
"

if [[ "$MODE" == all ]]; then
    BLOCK="$BLOCK
bind=CTRL+SUPER+ALT,space,spawn,$MENU_DIR/scripts/toggle-menu.sh
$KEYBINDS"
fi

if [ -f "$MANGO_CONF" ]; then
    ts="$(date +%Y%m%d-%H%M%S)"
    cp "$MANGO_CONF" "$MANGO_CONF.bak-$ts"

    if grep -q '^# >>> quickdots >>>$' "$MANGO_CONF"; then
        awk -v block="$BLOCK" '
            BEGIN { inblock = 0 }
            /^# >>> quickdots >>>$/ { print; print block; inblock = 1; next }
            /^# <<< quickdots <<<$/ { print; inblock = 0; next }
            inblock == 0 { print }
        ' "$MANGO_CONF" > "$MANGO_CONF.tmp"
    else
        cp "$MANGO_CONF" "$MANGO_CONF.tmp"
        {
            echo ""
            echo "# >>> quickdots >>>"
            echo "$BLOCK"
            echo "# <<< quickdots <<<"
        } >> "$MANGO_CONF.tmp"
    fi
    mv "$MANGO_CONF.tmp" "$MANGO_CONF"
fi

mmsg dispatch reload_config >/dev/null 2>&1 || true
