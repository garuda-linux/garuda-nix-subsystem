{ inputs, flake-lib, ... }: { config, lib, pkgs, flake-inputs, ... }:
let
  garuda-lib = flake-lib.garuda-lib { inherit config lib pkgs; };
in
with garuda-lib;
{
  options.garuda.excludes = gCreateExclusionOption "defaultpackages" // gCreateExclusionOption "kernelparameters";
  imports = [
    ./boot.nix
    # ./gaming.nix
    ./hardware.nix
    ./mount-garuda.nix
    ./networking.nix
    ./nyx.nix
    ./programs.nix
    ./shells.nix
    ./sound.nix
    ./subsystem/subsystem.nix
  ];
  config = {
    _module.args.flake-inputs = inputs;
    _module.args.garuda-lib = garuda-lib;

    ## OS
    boot.tmp.useTmpfs = gDefault true;

    environment.systemPackages = with pkgs; gExcludableArray "defaultpackages" [
      curl
      exa
      fastfetch
      git
      htop
      killall
      micro
      screen
      tldr
      ugrep
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
      # Make builds run with low priority so my system stays responsive
      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";

      # Do garbage collections whenever there is less than 3GB free space left
      extraOptions = ''
        max-free = ${toString (1024 * 1024 * 1024)}
        min-free = ${toString (100 * 1024 * 1024)}
      '';

      # Do daily garbage collections
      gc = {
        automatic = gDefault true;
        dates = gDefault "daily";
        options = gDefault "--delete-older-than 7d";
      };

      settings = {
        # Allow using flakes & automatically optimize the nix store
        auto-optimise-store = gDefault true;
        experimental-features = gDefault [ "nix-command" "flakes" "recursive-nix" "ca-derivations" ];

        # Users allowed to use Nix
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

    # Clean results periodically
    systemd.services.nix-clean-result = {
      description = "Auto clean all result symlinks created by nixos-rebuild test";
      serviceConfig.Type = "oneshot";
      script = ''
        "${config.nix.package.out}/bin/nix-store" --gc --print-roots | "${pkgs.gawk}/bin/awk" 'match($0, /^(.*\/result) -> \/nix\/store\/[^-]+-nixos-system/, a) { print a[1] }' | xargs -r -d\\n rm
      '';
      before = [ "nix-gc.service" ];
      wantedBy = [ "nix-gc.service" ];
    };

    ## Service config
    # Bluetooth
    hardware.bluetooth.enable = gDefault true;

    # Handle ACPI events
    services.acpid.enable = gDefault true;

    # LAN discovery
    services.avahi = {
      enable = gDefault true;
      nssmdns = gDefault true;
    };

    # Ciscard blocks that are not in use by the filesystem
    services.fstrim.enable = gDefault true;

    # Firmware updater for machine hardware
    services.fwupd.enable = gDefault true;

    # Limit systemd journal size
    services.journald.extraConfig = gDefault ''
      SystemMaxUse=50M
      RuntimeMaxUse=10M
    '';

    # Enable locating files via locate
    services.locate = gDefault {
      enable = true;
      localuser = null;
      interval = "hourly";
      locate = pkgs.plocate;
    };

    # Power profiles daemon
    services.power-profiles-daemon.enable = gDefault true;

    # Docker
    virtualisation.docker = gDefault {
      autoPrune.enable = true;
      autoPrune.flags = [ "-a" ];
    };
  };
}