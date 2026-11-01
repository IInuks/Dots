{ config, lib, pkgs, ... }:

# Home-Manager-Modul fuer blobball. Einbinden z.B. in flake.nix des
# Home-Manager-Profils:
#
#   imports = [ ~/quickdots/blobball/home-manager-module.nix ];
#
# Installiert Quickshell und legt die Blob-Config unter
# ~/.config/quickshell/blob/ ab (nur die .qml-Dateien -- README/flake.nix
# etc. werden bewusst nicht mitkopiert). Start erfolgt weiterhin ueber
# mangos config.conf (siehe README, Abschnitt "Autostart & Keybind"),
# nicht ueber dieses Modul -- Home-Manager kuemmert sich nur um Paket +
# Dateien.
let
  blobballSrc = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (f: f.hasExt "qml") ./.;
  };
in
{
  home.packages = [ pkgs.quickshell ];

  xdg.configFile."quickshell/blob" = {
    source = blobballSrc;
    recursive = true;
  };
}
