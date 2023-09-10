{
  description = "Garuda Linux Nix subsystem flake ❄️";

  nixConfig.extra-substituters = [ "https://nyx.chaotic.cx" ];
  nixConfig.extra-trusted-public-keys = [
    "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
  ];

  inputs = {
    # The Chaotic's Nyx
    chaotic-nyx.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    chaotic-nyx.inputs.home-manager.follows = "home-manager";

    # Devshell to set up a development environment
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    # Common used input of our flake inputs
    flake-utils.url = "github:numtide/flake-utils";

    # If you need to, override this to use a different nixpkgs version
    # by default we follow Chaotic Nyx' nyxpkgs-unstable branch
    nixpkgs.follows = "chaotic-nyx/nixpkgs";

    # Have a local index of nixpkgs for fast launching of apps
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # Easy linting of the flake and all kind of other stuff
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS hardware database
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Home configuration management
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Spicetify
    spicetify-nix.url = "github:the-argus/spicetify-nix";
    spicetify-nix.inputs.flake-utils.follows = "flake-utils";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, ... }@inputs:
    let
      devShells = import ./devshell { inherit inputs nixpkgs lib; };
      internal = import ./internal { inputs = inputs // { inherit nixpkgs; }; inherit lib; };
      lib = import ./lib { inherit inputs nixpkgs internal; };
      inherit (inputs) flake-utils;
    in
    {
      inherit devShells internal lib;
    }
    // flake-utils.lib.eachDefaultSystem (system: {
      # The checks to run with "nix flake check"
      checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        hooks = {
          commitizen.enable = true;
          deadnix.enable = true;
          nil.enable = true;
          nixpkgs-fmt.enable = true;
          prettier.enable = true;
          shellcheck.enable = true;
          shfmt.enable = true;
          statix.enable = true;
          yamllint.enable = true;
        };
        settings.deadnix = {
          edit = true;
          hidden = true;
          noLambdaArg = true;
        };
        src = ./.;
      };

      # Formatter used with "nix fmt"
      formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    });
}
