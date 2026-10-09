{
  config,
  lib,
  pkgs,
  ...
}:
let
  garuda-update = pkgs.writeShellApplication {
    name = "garuda-update";
    runtimeInputs = with pkgs; [
      git
      nix
      nh
      coreutils
      garuda-nix-subsystem
    ];
    text = ''
      unset LD_PRELOAD LD_LIBRARY_PATH
      if [ "$EUID" -ne 0 ]; then
        sudo "$0" "$@"
        exit 1
      fi

      if [ "''${1:-}" = "--rollback" ]; then
        echo -e "\033[1;33m-->\033[1;34m Rolling back to previous generation 🍵\033[0m"
        nh os rollback --bypass-root-check
        exit 0
      fi

      if [ -f /etc/nixos/garuda-managed.json ]; then
        exec garuda-nix-subsystem update "$@"
      else
        FLAKE="''${GARUDA_FLAKE:-/etc/nixos}"
        echo -e "\033[1;33m-->\033[1;34m Updating flake inputs 🍵\033[0m"
        nix flake update --flake "$FLAKE"
        echo -e "\033[1;33m-->\033[1;34m Rebuilding system 🍵\033[0m"
        if nh os switch --bypass-root-check "$FLAKE"; then
          git -C "$FLAKE" add flake.lock
          git -C "$FLAKE" -c user.name="garuda-update" -c user.email="garuda-update@localhost" commit -m "chore(flake.lock): $(date +%F)" --no-verify --quiet || true
        fi
      fi
    '';
  };
in
{
  config = {
    environment.systemPackages =
      lib.optionals (config.garuda.system.isGui || config.garuda.managed.config != null) [
        garuda-update
      ]
      ++ lib.optionals (config.garuda.managed.config != null) [
        pkgs.garuda-nix-subsystem
      ];
  };
}
