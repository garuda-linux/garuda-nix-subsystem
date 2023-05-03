{ pkgs
, ...
}: {
  # Gaming packages
  environment.systemPackages = with pkgs; [
    lutris
    mangohud
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
  programs.gamemode.enable = true;

  # Instant replays
  services.replay-sorcery = {
    enable = true;
    autoStart = false;
    settings = {
      videoQuality = "auto";
    };
  };

  # Enable Steam
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  # Unstable gamescope from Chaotic-Nyx
  chaotic.gamescope = {
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
  boot.kernel.sysctl = {
    "abi.vsyscall32" = 0;
  };
}
