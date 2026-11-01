#!/usr/bin/env bash
# Removes a custom bar entirely: its bars/ folder, adapter JSON and saved
# config. Refuses to touch anything if it's the currently active bar --
# the caller (BarEditor) should switch away first.
set -euo pipefail

SLUG="${1:?usage: delete-custom-bar.sh <slug>}"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MENU_DIR="$ROOT/menu"
BARS_DIR="$ROOT/bars"
STATE_DIR="$HOME/.local/state/quickdots"

ACTIVE="$(cat "$STATE_DIR/active-bar" 2>/dev/null || true)"
if [ "$ACTIVE" = "custom-$SLUG" ]; then
    echo "Fehler: custom-$SLUG ist aktuell aktiv -- erst zu einer anderen Bar wechseln" >&2
    exit 1
fi

rm -rf "$BARS_DIR/custom-$SLUG"
rm -f "$MENU_DIR/adapters/custom-$SLUG.json"
rm -f "$STATE_DIR/custom-bars/$SLUG.json"

echo "ok"
