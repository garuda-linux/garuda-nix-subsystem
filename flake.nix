{
  description = "Garuda Linux Nix subsystem flake";

  inputs = {
    # The Chaotic's Nyx
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # If you need to, override this to use a different nixpkgs version
    # by default we follow chaotic's nixpkgs-unstable branch
    garuda-nixpkgs.follows = "chaotic/nixpkgs";

    # Needed for find-the-command
    flake-programs-sqlite = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "garuda-nixpkgs";
    };

    # Home configuration management
    home-manager = {
      inputs.nixpkgs.follows = "garuda-nixpkgs";
      url = "github:garuda-linux/home-manager/master";
    };
  };

  outputs = { garuda-nixpkgs, ... }@inputs: rec {
    nixpkgs = garuda-nixpkgs;

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;

    devShells = import ./devshells { inherit inputs nixpkgs formatter lib; };

    internal = import ./internal { inputs = inputs // { inherit nixpkgs; }; inherit lib; };

    lib = import ./lib { inherit inputs nixpkgs internal; };
  };

  nixConfig = {
    extra-substituters = [ "https://nyx.chaotic.cx" ];
    extra-trusted-public-keys = [
      "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    ];
  };
}
