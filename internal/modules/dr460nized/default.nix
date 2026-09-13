{
  config,
  lib,
  pkgs,
  garuda-lib,
  ...
}:
with garuda-lib;
let
  cfg = config.garuda.dr460nized;
in
{
  imports = [ ./apps.nix ];
  options = {
    garuda.dr460nized = {
      enable = lib.mkOption {
        default = false;
        example = true;
        description = ''
          Dr460nized edition: vibrant Sweet-themed Plasma 6 gaming desktop,
          with matching login theme, apps and defaults. Mutually
          exclusive with garuda.mokka.
        '';
        type = lib.types.bool;
      };
      themePackage = lib.mkOption {
        default = pkgs.dr460nized-kde-theme;
        description = ''
          Plasma look-and-feel package (global theme, window decorations,
          login screen) applied to the desktop.
        '';
        type = lib.types.package;
        example = pkgs.kdePackages.breeze;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    garuda.system.type = "dr460nized";

    services.desktopManager.plasma6.enable = gDefault true;
    services.desktopManager.plasma6.enableQt5Integration = gDefault false;

    services.displayManager = {
      enable = gDefault true;
      plasma-login-manager.enable = gDefault true;
    };
    environment.etc."plasmalogin.conf.d/dr460nized.conf".text = ''
      [Greeter][Wallpaper][org.kde.image][General]
      Image=file://${cfg.themePackage}/share/wallpapers/Maldrakor/contents/3840x1920.jpg
    '';

    environment.plasma6.excludePackages = with pkgs; [
      # Pulls in 600 mb worth of mbrola (via espeak), which is a bit silly
      kdePackages.okular
      kdePackages.oxygen
      kdePackages.plasma-browser-integration
      kdePackages.discover
    ];

    # Fix "the name ca.desrt.dconf was not provided by any .service files"
    # https://nix-community.github.io/home-manager/index.html
    programs.dconf.enable = true;

    fonts = {
      enableDefaultPackages = gDefault false;
      packages =
        with pkgs;
        gExcludableArray config "defaultpackages" [
          fira
          nerd-fonts.jetbrains-mono
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
        ];
      fontconfig = {
        cache32Bit = gDefault true;
        defaultFonts = {
          monospace = gDefault [
            "JetBrains Mono Nerd Font"
            "Noto Fonts Emoji"
          ];
          sansSerif = gDefault [
            "Fira"
            "Noto Fonts Emoji"
          ];
          serif = gDefault [
            "Fira"
            "Noto Fonts Emoji"
          ];
          emoji = gDefault [ "Noto Fonts Emoji" ];
        };
        enable = gDefault true;
      };
      fontDir = {
        enable = gDefault true;
        decompressFonts = gDefault true;
      };
    };

    garuda.home-manager.modules = gExcludableArray config "home-manager-modules" [
      (lib.mkBefore ./metafiles.nix)
    ];

    programs = {
      direnv = {
        enable = gDefault true;
        silent = gDefault true;
      };
      kdeconnect.enable = gDefault true;
      partition-manager.enable = gDefault true;
    };

    environment.variables = {
      ALSOFT_DRIVERS = gDefault "pipewire";
      GTK_THEME = gDefault "Sweet-Dark";
      MOZ_USE_XINPUT2 = gDefault "1";
      QT_STYLE_OVERRIDE = gDefault "kvantum";
      SDL_AUDIODRIVER = gDefault "pipewire";
    };

    qt = {
      enable = true;
      platformTheme = "kde";
      style = "kvantum";
    };

    xdg.portal.extraPortals = gDefault [ pkgs.xdg-desktop-portal-gtk ];

    garuda.create-home.skel = gDefault "${gGenerateSkel pkgs "${cfg.themePackage}/skel" "dr460nized"}";
  };
}
