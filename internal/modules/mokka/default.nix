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
          If enabled, Garuda Linux's Mokka config will be used.
        '';
        type = lib.types.bool;
      };
      themePackage = lib.mkOption {
        default = pkgs.mokka-kde-theme;
        description = ''
          The theme package to use.
        '';
        type = lib.types.package;
        example = pkgs.libsForQt5.breeze-qt5;
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

    services.xserver = {
      enable = gDefault true;
    };

    environment.plasma6.excludePackages = with pkgs; [
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

    xdg.portal.extraPortals = gDefault [ pkgs.xdg-desktop-portal-gtk ];

    garuda.create-home.skel = gDefault "${gGenerateSkel pkgs "${cfg.themePackage}/skel" "mokka"}";
  };
}
