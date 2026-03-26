{
  description = "Vala dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "flexperimental";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            vala
            meson
            ninja
            pkg-config
            gobject-introspection
            wrapGAppsHook4
          ];

          buildInputs = with pkgs; [
            gtk4
            glib
            gtk4-layer-shell
          ];
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            vala
            meson
            ninja
            pkg-config
            gtk4
            glib
            gtk4-layer-shell
            gobject-introspection
            vala-language-server
            vala-lint
          ];
        };
      }
    );
}
