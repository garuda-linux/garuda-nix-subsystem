{
  pkgs,
  lib,
  flake-inputs,
  ...
}:
{
  imports = [
    # NixOS graphical Calamares installer ISO. The overlay in this flake
    # swaps calamares-nixos-extensions for the Garuda variant, so no need to override the module here.
    "${flake-inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix"
  ];

  environment.defaultPackages = lib.mkForce [
    pkgs.rsync
    pkgs.gparted
    pkgs.vim
    pkgs.nano
    pkgs.mesa-demos
  ];

  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };
}
