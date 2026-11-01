#!/bin/sh
# Remote server over SSH (Tailscale). Used by services/Server.qml.
#   server.sh stats HOST FALLBACK [USER]   one stats sample on stdout
#   server.sh shell HOST FALLBACK [USER]   interactive ssh (run inside a terminal)
#   server.sh setup HOST FALLBACK [USER]   create a key if needed and copy it to the server
# HOST is tried as a name first (MagicDNS / /etc/hosts), then via `tailscale ip`,
# then FALLBACK (an IP). A shared control socket keeps polling cheap, and a
# password login in the shell keeps the stats working for 4 h afterwards.

mode=$1 host=$2 fallback=$3 user=$4

target=$host
if ! getent hosts "$host" >/dev/null 2>&1; then
    ip=$(tailscale ip -4 "$host" 2>/dev/null | head -1)
    target=${ip:-${fallback:-$host}}
fi
[ -n "$user" ] && target="$user@$target"

sock="${XDG_RUNTIME_DIR:-/tmp}/salbei-ssh-%r@%h:%p"
opts="-o ControlMaster=auto -o ControlPath=$sock -o ControlPersist=4h -o ConnectTimeout=5 -o ServerAliveInterval=10"

case $mode in
stats)
    # timeout: Tailscale SSH in "check" mode waits for a browser login and
    # would otherwise hang forever (stderr has the login.tailscale.com URL).
    # shellcheck disable=SC2016
    exec timeout 15 ssh $opts -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$target" '
        echo "H $(hostname) $(uname -r)"
        head -1 /proc/stat
        grep -E "^(MemTotal|MemAvailable|SwapTotal|SwapFree):" /proc/meminfo
        echo "U $(cut -d" " -f1 /proc/uptime)"
        echo "L $(cut -d" " -f1-3 /proc/loadavg) $(nproc)"
        awk "NR>2 && \$1 !~ /^(lo|tailscale|docker|veth|br-)/ { gsub(\":\",\" \"); rx+=\$2; tx+=\$10 } END { print \"N\", rx+0, tx+0 }" /proc/net/dev
        for h in /sys/class/hwmon/hwmon*; do
            [ -r "$h/temp1_input" ] && echo "T $(cat "$h/name") $(cat "$h/temp1_input")"
        done 2>/dev/null
        df -B1 -P -x tmpfs -x devtmpfs -x overlay -x squashfs -x efivarfs 2>/dev/null |
            awk "NR>1 && \$1 ~ /^\// { print \"D\", \$2, \$3, \$6 }"
        ps -eo pcpu=,pmem=,comm= --sort=-pcpu 2>/dev/null | head -6 | awk "{ print \"P\", \$0 }"
    '
    ;;
shell)
    exec ssh $opts "$target"
    ;;
setup)
    [ -f "$HOME/.ssh/id_ed25519" ] || ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519" || exit 1
    ssh-copy-id -i "$HOME/.ssh/id_ed25519.pub" "$target" && echo "Key copied to $target."
    printf "Press Enter to close. "; read -r _
    ;;
esac
