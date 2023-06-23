{ config
, garuda-lib
, pkgs
, ...
}:
let
  cfg = config.garuda.gaming;
in
with garuda-lib;
{
  options = {
    garuda.gaming.enable =
      mkOption {
        default = true;
        description = ''
          If set to true, reasonable defaults for networking will be set.
        '';
      };
  };

  config = mkIf cfg.enable {
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
    services.replay-sorcery = gDefault {
      enable = true;
      autoStart = false;
      settings = {
        videoQuality = "auto";
      };
    };

    # Enable Steam
    programs.steam = gDefault {
      enable = true;
      gamescopeSession.enable = true;
    };

    # Unstable gamescope from Chaotic-Nyx
    chaotic.gamescope = gDefault {
      enable = true;
      package = pkgs.gamescope_git;
      args = [ "--rt" "--prefer-vk-device 1022:1630" ];
      env = { "__GLX_VENDOR_LIBRARY_NAME" = "amd"; };
      session = {
        enable = true;
        args = [ "--rt" ];
      };
    };

    # Fix League of Legends
    boot.kernel.sysctl = gDefault {
      "abi.vsyscall32" = 0;
    };
  };
}
