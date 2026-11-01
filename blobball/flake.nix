{
  description = "blobball -- schwebender Quickshell-Blob fuer mango";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.quickshell
            pkgs.qt6.qtdeclarative
            pkgs.qt6.qtshadertools
          ];

          shellHook = ''
            echo "blobball devShell -- Testlauf:"
            echo "  qs -p $(pwd) -n"
          '';
        };
      });
}
