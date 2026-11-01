#!/usr/bin/env bash
# Sets mango's global blur options for the "Blur" tab and reloads the config
# live (mango re-applies blur_params on reload_config).
#
# Usage: set-blur.sh key=value [key=value ...]
#   keys: blur blur_layer blur_optimized blur_params_num_passes
#         blur_params_radius blur_params_noise blur_params_brightness
#         blur_params_contrast blur_params_saturation
#
# Only replaces the existing "key = value" line (outside the quickdots
# block); a missing key is appended under "# Window effect" or at the end.
# Makes one backup per day (config.conf.bak-YYYYMMDD-blur), not one per
# slider move.

set -euo pipefail

CONF="$HOME/.config/mango/config.conf"
ALLOWED=" blur blur_layer blur_optimized blur_params_num_passes blur_params_radius blur_params_noise blur_params_brightness blur_params_contrast blur_params_saturation "

[ -f "$CONF" ] || { echo "Fehler: $CONF fehlt" >&2; exit 1; }
[ $# -gt 0 ] || { echo "usage: set-blur.sh key=value ..." >&2; exit 2; }

backup="$CONF.bak-$(date +%Y%m%d)-blur"
[ -f "$backup" ] || cp "$CONF" "$backup"

for pair in "$@"; do
    key="${pair%%=*}"
    val="${pair#*=}"
    case "$ALLOWED" in *" $key "*) ;; *) echo "Fehler: unbekannte Option $key" >&2; exit 2 ;; esac
    [[ "$val" =~ ^[0-9]+(\.[0-9]+)?$ ]] || { echo "Fehler: ungültiger Wert $val" >&2; exit 2; }

    if grep -qE "^[[:space:]]*$key[[:space:]]*=" "$CONF"; then
        sed -i -E "s|^[[:space:]]*$key[[:space:]]*=.*|$key=$val|" "$CONF"
    elif grep -q "^# Window effect" "$CONF"; then
        sed -i "/^# Window effect/a $key=$val" "$CONF"
    else
        printf '%s=%s\n' "$key" "$val" >> "$CONF"
    fi
done

mmsg dispatch reload_config >/dev/null
