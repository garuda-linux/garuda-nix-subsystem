# Managed setup, like build_subsystem_flake in garuda_template.py plus nixos-lima
{
  description = "Garuda Linux Nix Subsystem Flake";

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
      nixosConfigurations.garuda-lima-nix = garuda.lib.garudaSystem {
        system = "@SYSTEM@";
        specialArgs = { inherit inputs; };
        modules = [ ./configuration.nix ];
      };
    };
}
