# Generate a basic flake
{
  description = "Garuda Linux Nix subsystem updater flake (internal only!) ❄️";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { nixpkgs, ... }: {
    packages = nixpkgs.lib.mapAttrs (_: package: { inherit (package) nix; }) nixpkgs.legacyPackages;
  };
}
