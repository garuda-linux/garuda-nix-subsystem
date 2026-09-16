{ pkgs, treefmt-nix }:
let
  treefmt = treefmt-nix.lib.evalModule pkgs {
    projectRootFile = "flake.nix";
    settings.global.excludes = [
      "packages/calamares-nixos-extensions/template/**"
    ];
    programs = {
      deadnix.enable = true;
      nixfmt.enable = true;
      prettier.enable = true;
      ruff.enable = true;
      shellcheck.enable = true;
      shfmt.enable = true;
      statix.enable = true;
    };
  };
in
treefmt.config.build.wrapper
