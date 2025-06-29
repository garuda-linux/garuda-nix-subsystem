{ config
, garuda-lib
, pkgs
, lib
, ...
}:
let
  cfg = config.garuda.gaming;
in
with garuda-lib; {
  options.garuda.gaming = {
    enable = lib.mkOption {
      default = false;
      description = ''
        Installs and enables some gaming packages and services.
      '';
      example = true;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    # Gaming packages
    environment.systemPackages = with pkgs; [
      lutris
      mangohud
      prismlauncher
      (retroarch.overrideAttrs {
        cores = with libretro; [
          citra
          flycast
          ppsspp
        ];
      })
      wine-staging
      winetricks
    ];

    # Enable gamemode
    programs.gamemode.enable = gDefault true;

    # Enable Steam
    programs.steam = {
      enable = gDefault true;
      gamescopeSession.enable = gDefault true;
    };
  };
}
