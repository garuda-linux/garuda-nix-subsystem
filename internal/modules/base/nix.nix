{ config
, flake-inputs
, garuda-lib
, pkgs
, ...
}:
with garuda-lib;
{
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
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    settings = {
      # Allow using flakes & automatically optimize the nix store
      auto-optimise-store = gDefault true;
      experimental-features = [ "nix-command" "flakes" ];

      # Users allowed to use Nix
      allowed-users = [ "@wheel" ];
      trusted-users = [ "@wheel" ];

      # Max number of parallel jobs
      max-jobs = gDefault "auto";
    };
    nixPath = [ "nixpkgs=${flake-inputs.nixpkgs}" "nyx=${flake-inputs.chaotic}" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = gDefault true;

  # Print a diff when running system updates
  system.activationScripts.diff = ''
    if [[ -e /run/current-system ]]; then
      (
        for i in {1..3}; do
          result=$(${config.nix.package}/bin/nix store diff-closures /run/current-system "$systemConfig" 2>&1)
          if [ $? -eq 0 ]; then
            printf '%s\n' "$result"
            break
          fi
        done
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
}
