{ inputs, ... }: { flake-inputs, ... }:
{
  imports = [
    ./boot.nix
    ./create-home.nix
    ./gaming.nix
    ./garuda-update.nix
    ./hardware.nix
    ./home-manager/home-manager.nix
    ./locales.nix
    ./mount-garuda.nix
    ./networking.nix
    ./nix.nix
    ./nyx.nix
    ./performance.nix
    ./programs.nix
    ./services.nix
    ./shells.nix
    ./sound.nix
    ./subsystem/subsystem.nix
  ];
  _module.args.flake-inputs = inputs;
}
