{ inputs, ... }: { config, lib, pkgs, flake-inputs, ... }:
{
  _module.args.flake-inputs = inputs;
  imports = [ ./nyx.nix ];

  ## Network
  networking.networkmanager.enable = lib.mkDefault true;

  ## OS
  boot.tmp.useTmpfs = lib.mkDefault true;

  services.earlyoom.enable = lib.mkDefault true;
  services.locate = {
    enable = true;
    localuser = null;
    locate = pkgs.plocate;
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    killall
    micro
    screen
    wget
  ];

  # Kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_cachyos;

  # General nix settings
  nix = {
    # Do garbage collections whenever there is less than 3GB free space left
    extraOptions = ''
      min-free = ${toString (1024 * 1024 * 1024 * 3)}
    '';
    # Do daily garbage collections
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
    settings = {
      # Allow using flakes
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
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
    autoPrune.enable = lib.mkDefault true;
    autoPrune.flags = lib.mkDefault [ "-a" ];
  };
}
