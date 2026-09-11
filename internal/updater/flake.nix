# Generate a basic flake
{
  description = "Garuda Linux Nix subsystem updater flake (internal only!) ❄️";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
  };

  outputs =
    { nixpkgs, ... }:
    {
      packages = nixpkgs.lib.mapAttrs (_: package: { inherit (package) nix; }) nixpkgs.legacyPackages;
    };
}
