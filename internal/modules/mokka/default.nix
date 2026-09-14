{
  config,
  lib,
  pkgs,
  garuda-lib,
  ...
}:
with garuda-lib;
let
  cfg = config.garuda.mokka;
in
{
  imports = [ ./apps.nix ];
  options = {
    garuda.mokka = {
      enable = lib.mkOption {
        default = false;
        example = true;
        description = ''
          Mokka edition: calm dark Plasma 6 desktop in the Catppuccin
          Mocha palette, with matching login theme, apps and defaults.
          Mutually exclusive with garuda.dr460nized.
        '';
        type = lib.types.bool;
      };
      themePackage = lib.mkOption {
        default = pkgs.mokka-kde-theme;
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
    assertions = [
      {
        assertion = !config.garuda.dr460nized.enable;
        message = "garuda.mokka and garuda.dr460nized cannot be enabled at the same time.";
      }
    ];

    garuda.system.type = lib.mkIf (!config.garuda.dr460nized.enable) "mokka";

    services.desktopManager.plasma6.enable = gDefault true;
    services.desktopManager.plasma6.enableQt5Integration = gDefault false;

    services.displayManager = {
      enable = gDefault true;
      plasma-login-manager.enable = gDefault true;
    };
    environment.etc."plasmalogin.conf.d/mokka.conf".text = ''
      [Greeter][Wallpaper][org.kde.image][General]
      Image=file://${cfg.themePackage}/share/wallpapers/Mokka-tree/contents/images/3840x2160.jpg
    '';

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      discover
      elisa
      gwenview
      khelpcenter
      kwin-x11
      okular
      oxygen
      plasma-browser-integration
      plasma-keyboard
      qtvirtualkeyboard
    ];
    services.orca.enable = gDefault false;

    # Fix "the name ca.desrt.dconf was not provided by any .service files"
    # https://nix-community.github.io/home-manager/index.html
    programs.dconf.enable = true;

    fonts = {
      enableDefaultPackages = gDefault false;
      packages =
        with pkgs;
        gExcludableArray config "defaultpackages" [
          inter
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
            "Inter"
            "Noto Fonts Emoji"
          ];
          serif = gDefault [
            "Inter"
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
      GTK_THEME = gDefault "Catppuccin-Mocha-Standard-Mauve-Dark";
      MOZ_USE_XINPUT2 = gDefault "1";
      QT_STYLE_OVERRIDE = gDefault "kvantum";
      SDL_AUDIODRIVER = gDefault "pipewire";
    };

    qt = {
      enable = true;
      platformTheme = "kde";
    };

    environment.systemPackages = [ pkgs.qt6Packages.qtstyleplugin-kvantum ];

    catppuccin = {
      autoEnable = gDefault false;
      enable = gDefault false;
    };

    xdg.portal.extraPortals = gDefault [ pkgs.xdg-desktop-portal-gtk ];

    garuda.create-home.skel = gDefault "${gGenerateSkel pkgs "${cfg.themePackage}/skel" "mokka"}";
  };
}
