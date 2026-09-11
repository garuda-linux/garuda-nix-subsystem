{ pkgs, treefmt-nix }:
let
  treefmt = treefmt-nix.lib.evalModule pkgs {
    projectRootFile = "flake.nix";
    programs = {
      deadnix.enable = true;
      nixfmt.enable = true;
      prettier.enable = true;
      shellcheck.enable = true;
      shfmt.enable = true;
      statix.enable = true;
    };
  };
in
treefmt.config.build.wrapper
