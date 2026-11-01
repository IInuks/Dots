#!/usr/bin/env bash
# Finalizes one custom bar after the editor (CustomBarsStore.qml) has
# already written its config to
# ~/.local/state/quickdots/custom-bars/<slug>.json via FileView+JsonAdapter.
# This script scaffolds/updates the bars/custom-<slug>/ folder (shell.qml +
# symlink to the shared module library -- see the "outside of config
# folder" note in CustomBarRoot.qml), and (re)writes
# menu/adapters/custom-<slug>.json so the existing
# BarTheme/ThemeAdapter/BarCard machinery treats it like any other bar with
# zero changes to those files.
#
# Usage: save-custom-bar.sh <slug>
#
# "adaptive" theme mode is NOT resolved here -- CustomBarRoot.qml (the
# running bar) and CustomLive.qml (this menu's "Bars" tab card) both read
# ~/.cache/wal/colors.json live, which shellwall keeps current on every
# wallpaper change. _write_custom_adapter.py only mirrors that file once
# into adapters/custom-$SLUG.json as a fallback shown before the live
# reader has loaded.

set -euo pipefail

SLUG="${1:?usage: save-custom-bar.sh <slug>}"
MENU_DIR="~/quickdots/menu"
BARS_DIR="~/quickdots/bars"
STATE_DIR="$HOME/.local/state/quickdots/custom-bars"
BAR_DIR="$BARS_DIR/custom-$SLUG"

if [ ! -f "$STATE_DIR/$SLUG.json" ]; then
    echo "Fehler: $STATE_DIR/$SLUG.json nicht gefunden -- Config muss vor diesem Skript geschrieben sein" >&2
    exit 1
fi

mkdir -p "$BAR_DIR"
ln -sfn ../../lib/custombar "$BAR_DIR/lib"
cat > "$BAR_DIR/shell.qml" <<EOF
import Quickshell
import "lib"
ShellRoot { CustomBarRoot { slug: "$SLUG" } }
EOF

python3 "$MENU_DIR/scripts/_write_custom_adapter.py" "$STATE_DIR/$SLUG.json" "$MENU_DIR/adapters/custom-$SLUG.json"

echo "ok"
