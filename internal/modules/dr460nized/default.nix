{ ... }: { config, lib, pkgs, ... }:
let
  cfg = config.garuda.dr460nized;
in
{
  options = {
    garuda.dr460nized.enable =
      lib.mkOption {
        default = true;
        description = ''
          If enabled, Garuda Linux's dr460nized config will be used.
        '';
    };
  };
  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;

    environment.plasma5.excludePackages = with pkgs; [
      # Pulls in 600 mb worth of mbrola (via espeak), which is a bit silly
      okular
    ];
  };
}
