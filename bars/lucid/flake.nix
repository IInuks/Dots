{
  description = "lucid -- Material 3 Expressive pill bar for mango (Quickshell), Lucid-inspired reimplementation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in
    {
      # The QML tree as a plain derivation -- consumed by the HM module
      # below, or usable standalone with `qs -p <this-store-path>`.
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "lucidbar";
            version = "0.1.0";
            src = ./.;
            dontBuild = true;
            installPhase = ''
              mkdir -p $out/share/quickdots/lucidbar
              cp -r "$src"/*.qml "$src"/Bar "$src"/Panels "$out/share/quickdots/lucidbar/"
            '';
          };
        });

      # home.file.".config/quickshell/lucidbar".source = <this> puts the QML
      # where `qs -c lucidbar` (or bars/*'s own `qs -p`) finds it, matches
      # the "quickshell detects <xdg dir>/quickshell/<name>/shell.qml"
      # convention from `qs --help`. The optional `programs.quickshell.configs`
      # route mentioned in the original brief does not exist in current
      # nixpkgs/home-manager (checked: no such module ships), so this direct
      # home.file placement is the actual mechanism, not a fallback.
      homeManagerModules.lucidbar = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.lucidbar;
          lucidbarPkg = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
        in
        {
          options.programs.lucidbar = {
            enable = lib.mkEnableOption "the lucid Quickshell bar for mango";
          };

          config = lib.mkIf cfg.enable {
            home.packages = with pkgs; [
              quickshell
              qt6.qt5compat
              qt6.qtdeclarative
              qt6.qtmultimedia
              networkmanager # nmcli
              bluez # bluetoothctl
              wireplumber # wpctl
              libpulseaudio
              brightnessctl
              upower
              cava
              jq
              matugen
              material-symbols
              libnotify # notify-send
            ];

            home.file.".config/quickshell/lucidbar".source = "${lucidbarPkg}/share/quickdots/lucidbar";

            # Nudge, not an automatic config.conf edit -- this bar's brief
            # is explicit that nothing outside ~/.config/lucidbar and
            # ~/.cache/quickshell gets written to, and config.conf is
            # firmly outside that.
            home.activation.lucidbarAutostartHint = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              echo "lucidbar: add this to ~/.config/mango/config.conf to autostart:"
              echo "  exec-once=qs -c lucidbar -n &"
            '';
          };
        };

      # No configuration.nix/flake.nix on this machine currently imports any
      # Home-Manager module at all (plain NixOS, quickshell is a system
      # package in environment.systemPackages) -- see README "NixOS-
      # Integration" for the concrete activation path that actually applies
      # here today, and what adopting the module above would additionally
      # require.
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = [ pkgs.quickshell pkgs.qt6.qtdeclarative pkgs.qt6.qtshadertools ];
            shellHook = ''
              echo "lucid devShell -- test run:"
              echo "  qs -p $(pwd) -n"
            '';
          };
        });
    };
}
