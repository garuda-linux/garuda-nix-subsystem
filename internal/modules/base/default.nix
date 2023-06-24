{ inputs, flake-lib, ... }: { config, lib, pkgs, flake-inputs, ... }:
let
  garuda-lib = flake-lib.garuda-lib { inherit config lib pkgs; };
in
with garuda-lib;
{
  imports = [
    ./boot.nix
    # ./gaming.nix
    ./hardware.nix
    ./mount-garuda.nix
    ./networking.nix
    ./nix.nix
    ./nyx.nix
    # ./performance.nix
    ./programs.nix
    ./services.nix
    ./shells.nix
    ./sound.nix
    ./subsystem/subsystem.nix
  ];
  _module.args.flake-inputs = inputs;
  _module.args.garuda-lib = garuda-lib;
}
