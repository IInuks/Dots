#!/bin/sh
# Autostart for the salbei shell (called from mango exec-once).
# Waits for PipeWire first: Quickshell doesn't retry a failed PipeWire connection,
# so starting before pipewire-0 exists would leave volume/visualizer dead.
dir=$(dirname "$(dirname "$(readlink -f "$0")")")
i=0
while [ ! -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pipewire-0" ] && [ $i -lt 50 ]; do
    sleep 0.2
    i=$((i + 1))
done
exec qs -p "$dir" -n
