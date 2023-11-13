{ inputs, lib }:
_: prev:
let
  inherit (prev.hostPlatform) system;
  packages = import ./default.nix { inherit inputs lib system; pkgs = prev; };
in
{
  # TODO: Remove and replace with actual package
  inherit (packages.external) launch-terminal;
}
