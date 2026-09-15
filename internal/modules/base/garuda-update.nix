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
      nixos-rebuild
      coreutils
    ];
    text = ''
      unset LD_PRELOAD LD_LIBRARY_PATH
      if [ "$EUID" -ne 0 ]; then
        sudo "$0" "$@"
        exit 1
      fi

      if [ "''${1:-}" = "--rollback" ]; then
        echo -e "\033[1;33m-->\033[1;34m Rolling back to previous generation 🍵\033[0m"
        nixos-rebuild switch --rollback
        exit 0
      fi

      if [ -f /etc/nixos/garuda-managed.json ]; then
        echo -e "\033[1;33m-->\033[1;34m Downloading the latest version of the updater 🍵\033[0m"
        nix run --accept-flake-config gitlab:garuda-linux/garuda-nix-subsystem/stable?dir=internal/updater#nix -- develop --refresh --accept-flake-config gitlab:garuda-linux/garuda-nix-subsystem/stable#gns-update -c "gns-update"
      else
        FLAKE="''${GARUDA_FLAKE:-/etc/nixos}"
        echo -e "\033[1;33m-->\033[1;34m Updating flake inputs 🍵\033[0m"
        nix flake update --flake "$FLAKE"
        echo -e "\033[1;33m-->\033[1;34m Rebuilding system 🍵\033[0m"
        if nixos-rebuild switch --flake "$FLAKE"; then
          git -C "$FLAKE" add flake.lock
          git -C "$FLAKE" -c user.name="garuda-update" -c user.email="garuda-update@localhost" commit -m "chore(flake.lock): $(date +%F)" --no-verify --quiet || true
        fi
      fi
    '';
  };
in
{
  config = {
    environment.systemPackages = lib.mkIf (
      config.garuda.system.isGui || config.garuda.managed.config != null
    ) [ garuda-update ];
  };
}
