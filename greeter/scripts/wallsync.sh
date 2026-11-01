#!/bin/sh
# Keeps the greeter's wallpaper in sync with the session's awww wallpaper.
# Started from the mango config (exec-once); runs as the user.
#
# The greeter runs as _greeter and can't read ~ (0700), so the current image
# is copied to a shared dir that install.sh creates and hands to the user.
# It's converted to a screen-sized jpg on the way: Qt here can't load webp,
# and a smaller file loads faster at boot. awww has no change events, so
# poll cheaply every few seconds.
dest=${QD_GREETER_WALLDIR:-/bedrock/strata/arch/var/cache/qd-greeter/wall}
lock=${XDG_RUNTIME_DIR:-/tmp}/qd-greeter-wallsync.pid

# single instance
if [ -f "$lock" ] && kill -0 "$(cat "$lock")" 2>/dev/null; then exit 0; fi
echo $$ >"$lock"

sync_once() {
	[ -d "$dest" ] && [ -w "$dest" ] || return
	img=$(awww query 2>/dev/null | sed -n 's/.*image: //p' | head -n1)
	[ -n "$img" ] && [ -f "$img" ] || return
	# path + mtime, so an image replaced under the same name syncs too
	key="$img $(stat -c %Y "$img")"
	[ "$key" = "$(cat "$dest/source" 2>/dev/null)" ] && [ -f "$dest/wallpaper.jpg" ] && return
	magick "$img"'[0]' -auto-orient -resize '2560x1440^' -quality 90 "$dest/.wallpaper.jpg" 2>/dev/null || return
	chmod 644 "$dest/.wallpaper.jpg"
	mv -f "$dest/.wallpaper.jpg" "$dest/wallpaper.jpg"
	printf '%s\n' "$key" >"$dest/source"
}

while :; do
	sync_once
	sleep "${QD_GREETER_WALLSYNC_INTERVAL:-5}"
done
