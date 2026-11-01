#!/usr/bin/env bash
# Called by mango's SUPER+space keybind. Toggles the menu's standalone app
# search popup -- it no-ops for bars that already ship their own launcher
# (see SearchState.qml) -- same routed-through-a-script pattern as
# toggle-menu.sh.
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
exec qs -p "$ROOT/menu" ipc call launcher toggle
