{
  description = "Garuda Linux NixOS flake ❄️";

  inputs = {
    #
    # OS internals
    #

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #
    # Development tooling
    #

    devshell = {
      url = "github:numtide/devshell";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.flake-compat.follows = "flake-compat";
      inputs.gitignore.follows = "gitignore";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #
    # Deduplication
    #

    flake-compat.url = "github:edolstra/flake-compat";

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #
    # Theming
    #

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin-vsc = {
      url = "github:catppuccin/vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      flake-parts,
      nixpkgs,
      ...
    }@inputs:
    let
      internal = import ./internal {
        inherit lib;
        overlay = import ./packages/overlay.nix {
          inherit inputs lib;
        };
        inputs = inputs // {
          inherit nixpkgs;
        };
      };

      lib = import ./lib { inherit inputs nixpkgs internal; };

      perSystem =
        {
          pkgs,
          system,
          config,
          ...
        }:
        let
          packages = import ./packages {
            inherit
              system
              pkgs
              inputs
              lib
              ;
          };
        in
        {
          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              deadnix.enable = true;
              nixfmt.enable = true;
              prettier.enable = true;
              statix.enable = true;
              typos.enable = true;
            };
          };

          pre-commit.settings = {
            package = pkgs.prek;
            hooks = {
              commitizen.enable = true;
              check-json.enable = true;
              check-yaml.enable = true;
              deadnix.enable = true;
              flake-checker.enable = true;
              nil.enable = true;
              nixfmt.enable = true;
              prettier.enable = true;
              statix.enable = true;
              typos.enable = true;
            };
          };

          devshells = import ./devshell {
            inherit
              nixpkgs
              pkgs
              packages
              config
              ;
          };

          formatter = config.treefmt.build.wrapper;

          packages = packages.external;
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
        inputs.git-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake = {
        inherit lib;
        inherit internal;
      };

      inherit perSystem;
    };
}
