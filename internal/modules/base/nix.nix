{ overlay }:
{ config
, garuda-lib
, flake-inputs
, lib
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

    settings = {
      # Allow using flakes & automatically optimize the nix store
      auto-optimise-store = gDefault true;

      # Use available binary caches, this is not Gentoo
      # this also allows us to use remote builders to reduce build times and batter usage
      builders-use-substitutes = true;

      # We are using flakes, so enable the experimental features
      experimental-features = [ "nix-command" "flakes" ];

      # Users allowed to use Nix
      allowed-users = [ "@wheel" ];
      trusted-users = [ "@wheel" ];

      # Max number of parallel jobs
      max-jobs = gDefault "auto";
    };

    # Make legacy nix commands consistent as well
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    # Automtaically pin registries based on inputs
    registry = lib.mapAttrs (_: v: { flake = v; }) flake-inputs;
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
      "${config.nix.package.out}/bin/nix-store" --gc --print-roots \
        | "${pkgs.gawk}/bin/awk" 'match($0, /^(.*\/result) -> \/nix\/store\/[^-]+-nixos-system/, a) \
        { print a[1] }' | xargs -r -d\\n rm
    '';
    before = [ "nh-clean.service" ];
    wantedBy = [ "nh-clean.service" ];
  };

  # Overlays from the overlays folder
  nixpkgs.overlays = [
    overlay
  ];

  # Improved nix rebuild UX & cleanup timer
  programs.nh = {
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 10";
    };
    enable = true;
  };
}
