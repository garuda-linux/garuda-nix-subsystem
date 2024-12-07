{
  description = "Garuda Linux NixOS flake ❄️";

  nixConfig.extra-substituters = [
    "https://cache.garnix.io"
    "https://nyx.chaotic.cx"
  ];
  nixConfig.extra-trusted-public-keys = [
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
  ];

  inputs = {
    #
    # OS internals
    #

    # Chaotic's Nyx
    chaotic-nyx = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };

    # If you need to, override this to use a different nixpkgs version
    # by default we follow Chaotic Nyx' nyxpkgs-unstable branch
    nixpkgs.follows = "chaotic-nyx/nixpkgs";

    # Modules support for flakes
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "chaotic-nyx/nixpkgs";
    };

    # Have a local index of nixpkgs for fast launching of apps
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "chaotic-nyx/nixpkgs";
    };

    # Home configuration management
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "chaotic-nyx/nixpkgs";
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
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.flake-compat.follows = "chaotic-nyx/nixpkgs";
      inputs.nixpkgs.follows = "chaotic-nyx/nixpkgs";
      # Only used for the tests of pre-commit-hooks. Override stops double fetch
      inputs.nixpkgs-stable.follows = "chaotic-nyx/nixpkgs";
    };

    #
    # Theming
    #

    # Beautiful pastel theming
    catppuccin.url = "github:catppuccin/nix";
    catppuccin-vsc = {
      url = "github:catppuccin/vscode";
      inputs.nixpkgs.follows = "chaotic-nyx/nixpkgs";
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
