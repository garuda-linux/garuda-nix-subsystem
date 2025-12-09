{
  description = "Garuda Linux NixOS flake ❄️";

  inputs = {
    #
    # OS internals
    #

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Modules support for flakes
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Have a local index of nixpkgs for fast launching of apps
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home configuration management
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    #
    # Development tooling
    #

    # Devshell to set up a development environment
    devshell = {
      url = "github:numtide/devshell";
      flake = false;
    };

    # Easy linting of the flake and all kind of other stuff
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #
    # Theming
    #

    # Beautiful pastel theming
    catppuccin.url = "github:catppuccin/nix";
    catppuccin-vsc = {
      url = "github:catppuccin/vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { flake-parts
    , nixpkgs
    , pre-commit-hooks
    , ...
    } @ inputs:
    let
      internal = import ./internal {
        inherit lib;
        overlay = import ./packages/overlay.nix {
          inherit inputs lib;
        };
        inputs = inputs // { inherit nixpkgs; };
      };

      lib = import ./lib { inherit inputs nixpkgs internal; };

      perSystem =
        { pkgs
        , system
        , ...
        }:
        let
          packages = import ./packages { inherit system pkgs inputs lib; };
        in
        {
          checks.pre-commit-check = pre-commit-hooks.lib.${system}.run {
            hooks = {
              actionlint.enable = true;
              commitizen.enable = true;
              deadnix.enable = true;
              nil.enable = true;
              nixpkgs-fmt.enable = true;
              prettier.enable = true;
              statix.enable = true;
              yamllint.enable = true;
            };
            src = ./.;
          };

          devShells = import ./devshell {
            inherit inputs nixpkgs system pkgs packages;
          };

          formatter = pkgs.nixpkgs-fmt;

          packages = packages.external;
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Flake modules
      imports = [ inputs.pre-commit-hooks.flakeModule ];

      # The available systems
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # Regular flake stuff
      flake = {
        inherit lib;
        inherit internal;
      };

      # This applies to all systems
      inherit perSystem;
    };
}
