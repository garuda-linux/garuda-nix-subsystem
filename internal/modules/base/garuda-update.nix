{ pkgs
, ...
}:
let
  garuda-update = pkgs.writeShellApplication {
    name = "garuda-update";
    runtimeInputs = with pkgs; [ nix coreutils ];
    text = ''
      if [ "$EUID" -ne 0 ]; then
        sudo "$0" "$@"
        exit 1
      fi
      echo -e "\033[1;33m-->\033[1;34m Downloading the latest version of the updater 🍵\033[0m"
      nix develop --refresh --accept-flake-config gitlab:garuda-linux/garuda-nix-subsystem/v1#gns-update -c "gns-update"
    '';
  };
in
{
  config = {
    # This is the default updater for GNS (irrelevant for non-GNS users)
    environment.systemPackages = [ garuda-update ];
  };
}
