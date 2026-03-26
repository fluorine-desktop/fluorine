{
  description = "Vala dev environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in
  {
    packages.${system}.default = pkgs.stdenv.mkDerivation {
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
      ];
    };

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        vala
        meson
        ninja
        pkg-config
        gtk4
        glib
        gobject-introspection
        vala-language-server
        vala-lint
      ];
    };
  };
}
