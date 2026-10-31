# Plain Garuda Nix flake setup, like the installer template
{
  description = "Garuda NixOS configuration";
  nixConfig = {
    extra-substituters = [ "https://nyx-cache.chaotic.cx/" ];
    extra-trusted-public-keys = [
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    ];
  };

  inputs = {
    garuda.url = "@GARUDA_URL@";
    nixos-lima = {
      url = "github:nixos-lima/nixos-lima/v0.2.2";
      inputs.nixpkgs.follows = "garuda/nixpkgs";
    };
  };

  outputs =
    { garuda, ... }@inputs:
    {
      nixosConfigurations.garuda-lima = garuda.lib.garudaSystem {
        system = "@SYSTEM@";
        specialArgs = { inherit inputs; };
        modules = [ ./configuration.nix ];
      };
    };
}
