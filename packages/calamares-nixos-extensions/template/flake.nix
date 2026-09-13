# Garuda Nix configuration.
# Rebuild with `nixos-rebuild switch --flake /etc/nixos#@HOSTNAME@`.
{
  description = "Garuda NixOS configuration";

  inputs = {
    # This input brings Nixpkgs, home-manager, Chaotic-Nyx via garuda.lib.garudaSystem.
    # There is no need to specify them separately unless you have a reason to do so.
    garuda.url = "@GARUDAREF@";
  };

  outputs =
    {
      garuda,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # Reusable nixos modules you might want to export
      nixosModules = import ./modules/nixos;

      # Reusable home-manager modules you might want to export
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#@HOSTNAME@'
      nixosConfigurations."@HOSTNAME@" = garuda.lib.garudaSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [ ./nixos/configuration.nix ];
      };
    };
}
