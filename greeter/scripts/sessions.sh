#!/bin/sh
# Prints one line per visible Wayland session:
#   Name<TAB>Exec<TAB>DesktopNames<TAB>file
dir=${1:-/usr/share/wayland-sessions}
for f in "$dir"/*.desktop; do
    [ -f "$f" ] || continue
    awk -F= -v f="$f" '
        /^\[/ { s = ($0 == "[Desktop Entry]") }
        s && $1 == "Name" && n == ""         { n = substr($0, 6) }
        s && $1 == "Exec" && e == ""         { e = substr($0, 6) }
        s && $1 == "DesktopNames" && d == "" { d = substr($0, 14) }
        s && ($1 == "Hidden" || $1 == "NoDisplay") && $2 == "true" { h = 1 }
        END { if (!h && e != "") printf "%s\t%s\t%s\t%s\n", n, e, d, f }
    ' "$f"
done
