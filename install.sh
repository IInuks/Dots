#!/usr/bin/env bash
# Install quickdots runtime dependencies and connect its Quickshell configs.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
say() { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

USER_HOME="${HOME:?HOME must be set}"
if (( EUID == 0 )) && [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
    USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    [[ -n "$USER_HOME" ]] || die "Could not find the home directory for $SUDO_USER."
fi
CONFIG_DIR="$USER_HOME/.config"
QS_DIR="$CONFIG_DIR/quickshell"
WALLPAPER_DIR="$USER_HOME/Pictures/Walpapers"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat <<'USAGE'
Usage: ./install.sh

Installs available quickdots runtime packages with the detected package
manager, links the menu/shellwall/blobball Quickshell configs, copies the
repository wallpapers into ~/Pictures/Walpapers, and configures the default
quickdots bar in ~/.config/mango/config.conf.

MangoWM (mango + mmsg) must already be installed. Package installation may
ask for sudo; Nix installs into the current user's profile.
USAGE
    exit 0
fi
[[ $# -eq 0 ]] || die "Unknown argument: $1 (use --help)"

[[ "$ROOT" == "$USER_HOME/quickdots" ]] || warn "This checkout is at $ROOT. Some existing quickdots scripts currently expect $USER_HOME/quickdots; move/clone it there for bar switching to work."

OS_ID=""
OS_LIKE=""
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-}"
    OS_LIKE="${ID_LIKE:-}"
fi

run_privileged() {
    if (( EUID == 0 )); then "$@"; elif command -v sudo >/dev/null 2>&1; then sudo "$@"; else die "Need root privileges (install sudo or run as root)."; fi
}

install_packages() {
    local manager="$1"; shift
    local -a packages=("$@")
    case "$manager" in
        pacman) run_privileged pacman -Sy --needed --noconfirm "${packages[@]}" ;;
        apt) run_privileged apt-get update; run_privileged apt-get install -y "${packages[@]}" ;;
        dnf) run_privileged dnf install -y "${packages[@]}" ;;
        zypper) run_privileged zypper --non-interactive install "${packages[@]}" ;;
        xbps) run_privileged xbps-install -Sy "${packages[@]}" ;;
        apk) run_privileged apk add "${packages[@]}" ;;
        *) die "Unsupported package manager: $manager" ;;
    esac
}

install_bedrock_packages() {
    local -a packages=("$@")
    if (( EUID == 0 )); then
        strat arch pacman -Sy --needed --noconfirm "${packages[@]}"
    elif command -v sudo >/dev/null 2>&1; then
        sudo /bedrock/bin/strat arch pacman -Sy --needed --noconfirm "${packages[@]}"
    else
        die "Need root privileges to install packages in the Arch stratum."
    fi
}

say "Detecting distribution: ${OS_ID:-unknown}${OS_LIKE:+ (like $OS_LIKE)}"
case "$OS_ID" in
    bedrock)
        if command -v strat >/dev/null && strat arch command -v pacman >/dev/null 2>&1; then
            say "Bedrock Linux detected; using the Arch stratum package manager"
            install_bedrock_packages quickshell swww imagemagick matugen python-pywal wl-clipboard grim slurp brightnessctl playerctl cava jq curl
        else
            die "Bedrock Linux needs an Arch stratum with pacman. Install Quickshell and the runtime tools in a stratum, then rerun."
        fi
        ;;
    arch|manjaro|endeavouros)
        install_packages pacman quickshell swww imagemagick matugen python-pywal wl-clipboard grim slurp brightnessctl playerctl cava jq curl
        ;;
    debian|ubuntu|linuxmint|pop)
        install_packages apt imagemagick wl-clipboard grim slurp brightnessctl playerctl cava jq curl
        warn "Quickshell, awww/swww, matugen, and pywal are not consistently available in the default repositories for $OS_ID; install those from your distro/Nix and rerun."
        ;;
    fedora)
        install_packages dnf ImageMagick wl-clipboard grim slurp brightnessctl playerctl cava jq curl
        warn "Quickshell, awww/swww, matugen, and pywal may need an additional repository or Nix on Fedora."
        ;;
    opensuse*|sles)
        install_packages zypper ImageMagick wl-clipboard grim slurp brightnessctl playerctl cava jq curl
        warn "Quickshell, awww/swww, matugen, and pywal may need an additional repository or Nix on openSUSE."
        ;;
    void)
        install_packages xbps ImageMagick wl-clipboard grim slurp brightnessctl playerctl cava jq curl
        warn "Quickshell, awww/swww, matugen, and pywal availability varies in Void repositories."
        ;;
    alpine)
        install_packages apk imagemagick wl-clipboard grim slurp brightnessctl playerctl cava jq curl
        warn "Quickshell, awww/swww, matugen, and pywal may need additional Alpine repositories."
        ;;
    nixos)
        command -v nix >/dev/null || die "Nix was not found."
        nix profile install nixpkgs#quickshell nixpkgs#swww nixpkgs#imagemagick nixpkgs#matugen nixpkgs#pywal nixpkgs#wl-clipboard nixpkgs#grim nixpkgs#slurp nixpkgs#brightnessctl nixpkgs#playerctl nixpkgs#cava nixpkgs#jq nixpkgs#curl
        ;;
    *)
        if [[ " $OS_LIKE " == *" arch "* ]] && command -v pacman >/dev/null; then
            install_packages pacman quickshell swww imagemagick matugen python-pywal wl-clipboard grim slurp brightnessctl playerctl cava jq curl
        elif [[ " $OS_LIKE " == *" debian "* ]] && command -v apt-get >/dev/null; then
            install_packages apt imagemagick wl-clipboard grim slurp brightnessctl playerctl cava jq curl
            warn "Install Quickshell, awww/swww, matugen, and pywal from your distro/Nix."
        else
            die "Could not choose a supported package manager for ${OS_ID:-unknown}."
        fi
        ;;
esac

say "Creating Quickshell configuration links"
mkdir -p "$QS_DIR" "$USER_HOME/.local/state/quickshell" "$USER_HOME/.local/state/quickdots" "$USER_HOME/.cache" "$WALLPAPER_DIR"
link_config() {
    local name="$1" source="$2" target="$QS_DIR/$name"
    if [[ -e "$target" && ! -L "$target" ]]; then
        die "$target already exists and is not a symlink; move it aside and rerun to preserve your files."
    fi
    ln -sfn "$source" "$target"
}
link_config menu "$ROOT/menu"
link_config quickwall "$ROOT/shellwall"
link_config blob "$ROOT/blobball"

if [[ -d "$ROOT/wallpapers" ]]; then
    say "Copying repository wallpapers to $WALLPAPER_DIR (existing files are kept)"
    while IFS= read -r -d '' image; do
        name="${image##*/}"
        [[ -e "$WALLPAPER_DIR/$name" ]] || cp -- "$image" "$WALLPAPER_DIR/$name"
    done < <(find "$ROOT/wallpapers" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.avif' \) -print0)
fi

say "Checking MangoWM and quickdots runtime commands"
missing=()
for cmd in qs awww mmsg mango; do command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd"); done
if ((${#missing[@]})); then
    warn "Not found: ${missing[*]}. MangoWM itself must be installed separately; wallpaper and bar features may not work until these commands are available."
fi

if [[ -x "$ROOT/menu/scripts/mango-block.sh" && -d "$USER_HOME/.config/mango" ]]; then
    say "Adding the quickdots default bar and menu to MangoWM"
    "$ROOT/menu/scripts/mango-block.sh" simple
else
    warn "No MangoWM config found at ~/.config/mango/config.conf; configs are linked but autostart/keybind integration was skipped."
fi

say "Installation setup complete. Log out and back in to start the configured bar, or start MangoWM again."
