#!/bin/sh
# Installs the quickdots greeter under greetd (Void stratum).
#
#   sudo ./install.sh            install / update the greeter files + config
#   sudo ./install.sh --switch   ... and replace LightDM with greetd (ends
#                                the running graphical session!)
#   sudo ./install.sh --rollback switch back to LightDM
#
# Test greetd + greeter first from a TTY without switching:
#   sudo strat void sh -c 'sv down lightdm; greetd'   (Ctrl+Alt+F2 if stuck)
set -eu

# Everything below runs in the init stratum (runit, elogind, greetd).
if [ -z "${QD_IN_VOID:-}" ]; then
    QD_IN_VOID=1 exec /bedrock/bin/strat void /bin/sh "$(readlink -f "$0")" "$@"
fi

[ "$(id -u)" -eq 0 ] || { echo "run as root (sudo $0)"; exit 1; }

src=$(dirname "$(readlink -f "$0")")
dest=/etc/greetd/quickdots
stamp=$(date +%Y-%m-%d-%H%M)

rollback() {
    sv down greetd 2>/dev/null || true
    rm -f /var/service/greetd
    [ -e /var/service/lightdm ] || ln -s /etc/sv/lightdm /var/service/
    echo "LightDM is enabled again, greetd disabled."
}

case "${1:-}" in
    --rollback) rollback; exit 0 ;;
    --switch|"") ;;
    *) echo "unknown option: $1"; exit 1 ;;
esac

echo ":: packages"
for p in greetd cage; do
    xbps-query "$p" >/dev/null 2>&1 || xbps-install -Sy "$p"
done

echo ":: greeter user"
if ! id _greeter >/dev/null 2>&1; then
    useradd -r -M -d /var/lib/greetd -s /sbin/nologin _greeter
fi
usermod -aG video,input _greeter

echo ":: greeter files -> $dest"
mkdir -p "$dest"
rm -rf "$dest/components" "$dest/styles" "$dest/scripts"
cp -r "$src/components" "$src/styles" "$src/scripts" "$dest/"
cp "$src"/*.qml "$dest/"
[ -f "$src/wallpaper.jpg" ] && cp "$src/wallpaper.jpg" "$dest/"
chmod -R a+rX "$dest"

# The greeter's state file is written from the Arch stratum (qs runs there).
statedir=/bedrock/strata/arch/var/cache/qd-greeter
mkdir -p "$statedir"
chown _greeter "$statedir"
# scripts/wallsync.sh (run by the user in the session) copies the current
# wallpaper here; the greeter reads it
user=${SUDO_USER:-}
if [ -n "$user" ] && [ "$user" != root ]; then
    mkdir -p "$statedir/wall"
    chown "$user" "$statedir/wall"
    chmod 755 "$statedir/wall"
else
    echo "   (run via sudo to set up the wallpaper sync dir for your user)"
fi

echo ":: /etc/greetd/config.toml"
if [ -f /etc/greetd/config.toml ] && ! cmp -s "$src/greetd/config.toml" /etc/greetd/config.toml; then
    cp /etc/greetd/config.toml "/etc/greetd/config.toml.bak-$stamp"
fi
cp "$src/greetd/config.toml" /etc/greetd/config.toml

# Waits for elogind at boot (see greetd/sv-run). A greetd package update
# overwrites this -- just re-run install.sh.
echo ":: /etc/sv/greetd/run"
if ! cmp -s "$src/greetd/sv-run" /etc/sv/greetd/run; then
    cp /etc/sv/greetd/run "/etc/sv/greetd/run.bak-$stamp"
    install -m 755 "$src/greetd/sv-run" /etc/sv/greetd/run
fi

if [ "${1:-}" = "--switch" ]; then
    echo ":: switching LightDM -> greetd (this ends the graphical session)"
    sleep 2
    sv down lightdm 2>/dev/null || true
    rm -f /var/service/lightdm
    ln -sf /etc/sv/greetd /var/service/
else
    echo
    echo "Installed. LightDM is still the active login manager."
    echo "Switch with:   sudo $src/install.sh --switch"
    echo "Undo with:     sudo $src/install.sh --rollback"
fi
