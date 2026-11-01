#!/bin/sh
# Started by cage (greetd/config.toml) inside the Arch stratum, as _greeter.
#
# _greeter has no home, so cache/state/crash dumps go to the state dir, and
# qs output is kept in qs.log (previous start: qs.log.old) for debugging.
dir=/var/cache/qd-greeter
export HOME=$dir XDG_CACHE_HOME=$dir/cache XDG_STATE_HOME=$dir/state
export QD_GREETER_STATE=$dir/state.json
# the user's current wallpaper, kept up to date by scripts/wallsync.sh
[ -r "$dir/wall/wallpaper.jpg" ] && export QD_GREETER_WALLPAPER=$dir/wall/wallpaper.jpg
# cage offers no server-side decorations -- without this Qt draws its own
# frame and title bar around the fullscreen window.
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

[ -f "$dir/qs.log" ] && mv -f "$dir/qs.log" "$dir/qs.log.old"
{
	# context for boot-time crashes (greetd may start before elogind/dbus)
	echo "== $(date '+%F %T') uptime=$(cut -d' ' -f1 /proc/uptime)s $(id)"
	echo "== XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_SESSION_ID=$XDG_SESSION_ID"
	echo "== elogind: $(pgrep -x elogind >/dev/null && echo up || echo DOWN)  dbus: $(pgrep -x dbus-daemon >/dev/null && echo up || echo DOWN)"
} >"$dir/qs.log"
qs -n --log-times -p /bedrock/strata/void/etc/greetd/quickdots >>"$dir/qs.log" 2>&1
status=$?
echo "== qs exited with $status" >>"$dir/qs.log"
# crash reports are private to _greeter by default; make them readable
chmod -R a+rX "$dir" 2>/dev/null
exit $status
