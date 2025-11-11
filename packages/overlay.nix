{ inputs, lib }:
_: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
  packages = import ./default.nix { inherit inputs lib system; pkgs = prev; };
in
{
  inherit (packages.internal) garuda-nix-manager;
}
