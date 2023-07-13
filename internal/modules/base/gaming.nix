{ config
, garuda-lib
, pkgs
, lib
, ...
}:
let
  cfg = config.garuda.gaming;
in
with garuda-lib;
{
  options.garuda.gaming.enable = lib.mkOption {
    default = false;
    type = lib.types.bool;
    description = ''
      Installs and enables some gaming packages and services.
    '';
  };

  config = lib.mkIf cfg.enable {
    # Gaming packages
    environment.systemPackages = with pkgs; [
      lutris
      mangohud
      prismlauncher-qt5
      (retroarch.override {
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

    # Instant replays
    services.replay-sorcery = {
      enable = gDefault true;
      autoStart = false;
      settings = {
        videoQuality = "auto";
      };
    };

    # Enable Steam
    programs.steam = {
      enable = gDefault true;
      gamescopeSession.enable = gDefault true;
    };

    # Fix League of Legends
    boot.kernel.sysctl = {
      "abi.vsyscall32" = 0;
    };
  };
}
