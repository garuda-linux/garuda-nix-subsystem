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

    # Devshell to set up a development environment
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "garuda-nixpkgs";

    # If you need to, override this to use a different nixpkgs version
    # by default we follow Chaotic Nyx' nyxpkgs-unstable branch
    garuda-nixpkgs.follows = "chaotic-nyx/nixpkgs";

    # Have a local index of nixpkgs for fast launching of apps
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "garuda-nixpkgs";

    # Easy linting of the flake and all kind of other stuff
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

    # NixOS hardware database
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Home configuration management
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "garuda-nixpkgs";

    # Spicetify
    spicetify-nix.url = "github:the-argus/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "garuda-nixpkgs";
  };
  outputs =
    { devshell
    , flake-parts
    , garuda-nixpkgs
    , self
    , ...
    } @ inputs:
    rec {
      devShells = import ./devshells { inherit inputs nixpkgs lib; };
      internal = import ./internal { inputs = inputs // { inherit nixpkgs; }; inherit lib; };
      lib = import ./lib { inherit inputs nixpkgs internal; };
      nixpkgs = garuda-nixpkgs;
    } // flake-parts.lib.mkFlake
      { inherit inputs; }
      {
        imports = [
          ./devshells/flake-module.nix
          inputs.devshell.flakeModule
          inputs.pre-commit-hooks.flakeModule
        ];

        systems = [ "x86_64-linux" "aarch64-linux" ];

        perSystem = { pkgs, system, ... }: {
          # Enter devshell via "nix run .#apps.x86_64-linux.devshell"
          apps.devshell = self.outputs.devShells.${system}.default.flakeApp;

          # Defines a formatter for "nix fmt"
          formatter = pkgs.nixpkgs-fmt;
        };
      };

}
