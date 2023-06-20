{ inputs, flake-lib, ... }: { config, lib, pkgs, flake-inputs, ... }:
let
  garuda-lib = flake-lib.garuda-lib { inherit config lib pkgs; };
in
with garuda-lib;
{
  options.garuda.excludes = gCreateExclusionOption "defaultpackages" // gCreateExclusionOption "kernelparameters";
  imports = [
    ./networking.nix
    ./mount-garuda.nix
    ./nyx.nix
    ./sound.nix
    ./boot.nix
    ./shells.nix
  ];
  config = {
    _module.args.flake-inputs = inputs;
    _module.args.garuda-lib = garuda-lib;

    ## OS
    boot.tmp.useTmpfs = gDefault true;

    services.locate = {
      enable = gDefault true;
      localuser = gDefault null;
      locate = gDefault pkgs.plocate;
    };

    environment.systemPackages = with pkgs; gExcludableArray "defaultpackages" [
      curl
      git
      htop
      killall
      micro
      screen
      wget
    ];

    boot.kernelParams = gExcludableArray "kernelparameters" [
      "iommu=pt"
      "nopti"
      "nowatchdog"
      "rootflags=noatime"
      "split_lock_detect=off" # https://www.phoronix.com/news/Linux-Splitlock-Hurts-Gaming
      "systemd.gpt_auto=0" # https://github.com/NixOS/nixpkgs/issues/35681#issuecomment-370202008
      "tsx=on"
    ];

    # General nix settings
    nix = {
      # Do garbage collections whenever there is less than 3GB free space left
      extraOptions = ''
        min-free = ${toString (1024 * 1024 * 1024 * 3)}
      '';
      # Do daily garbage collections
      gc = {
        automatic = gDefault true;
        dates = gDefault "daily";
        options = gDefault "--delete-older-than 7d";
      };
      settings = {
        # Allow using flakes
        auto-optimise-store = gDefault true;
        experimental-features = gDefault [ "nix-command" "flakes" ];

        allowed-users = [ "@wheel" ];
        trusted-users = [ "@wheel" ];

        # Max number of parallel jobs
        max-jobs = gDefault "auto";
      };
      nixPath = [ "nixpkgs=${flake-inputs.nixpkgs}" "nyx=${flake-inputs.chaotic}" ];
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Print a diff when running system updates
    system.activationScripts.diff = ''
      if [[ -e /run/current-system ]]; then
        (
          for i in {1..3}; do
            garuda_diff_result=$(${config.nix.package}/bin/nix store diff-closures /run/current-system "$systemConfig" 2>&1)
            if [ $? -eq 0 ] && [ ! -z "$garuda_diff_result" ]; then
              printf '%s\n' "$result"
              break
            fi
          done
          unset garuda_diff_result
        )
      fi
    '';

    ## Service config
    # Docker
    virtualisation.docker = {
      autoPrune.enable = gDefault true;
      autoPrune.flags = gDefault [ "-a" ];
    };


    # Power profiles daemon
    services.power-profiles-daemon.enable = gDefault true;

    # LAN discovery
    services.avahi = {
      enable = gDefault true;
      nssmdns = gDefault true;
    };

    # Bluetooth
    hardware.bluetooth.enable = gDefault true;
  };
}
