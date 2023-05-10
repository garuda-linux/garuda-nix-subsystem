{
  description = "Garuda Linux Nix subsystem flake";

  inputs = {
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    flake-programs-sqlite.url = "github:wamserma/flake-programs-sqlite";
    flake-programs-sqlite.inputs.nixpkgs.follows = "chaotic/nixpkgs";
  };

  outputs = { chaotic, ... }@inputs: rec {
    inherit (chaotic.inputs) nixpkgs;

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;

    devShells = import ./devshells { inherit inputs nixpkgs formatter; };

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
