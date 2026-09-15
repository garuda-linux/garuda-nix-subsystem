{
  config,
  lib,
  pkgs,
  garuda-lib,
  ...
}:
with garuda-lib;
let
  cfg = config.garuda.kde;
  anyEdition = lib.any (e: config.garuda.${e}.enable or false) [
    "catppuccin"
    "dr460nized"
    "mokka"
  ];
in
{
  options = {
    garuda.kde = {
      ocrLang = lib.mkOption {
        default = [ "eng" ];
        description = ''
          Tesseract OCR languages bundled into Spectacle (screenshot tool).
        '';
        type = lib.types.listOf lib.types.str;
        example = [
          "eng"
          "deu"
        ];
      };
      fontPackage = lib.mkOption {
        default = pkgs.inter;
        description = ''
          Sans/serif interface font of the enabled edition.
        '';
        type = lib.types.package;
        example = pkgs.fira;
      };
      fontName = lib.mkOption {
        default = "Inter";
        description = ''
          Fontconfig name matching fontPackage.
        '';
        type = lib.types.str;
        example = "Fira";
      };
      themePackage = lib.mkOption {
        default =
          if config.garuda.mokka.enable then
            pkgs.mokka-kde-theme
          else if config.garuda.dr460nized.enable then
            pkgs.dr460nized-kde-theme
          else
            pkgs.catppuccin-kde;
        description = ''
          Plasma look-and-feel package (global theme, window decorations,
          login screen) applied to the desktop. Defaults to the theme of
          the enabled edition.
        '';
        type = lib.types.package;
        example = pkgs.kdePackages.breeze;
      };
      wallpaper = lib.mkOption {
        default =
          if config.garuda.mokka.enable then
            "share/wallpapers/Mokka-tree/contents/images/3840x2160.jpg"
          else if config.garuda.dr460nized.enable then
            "share/wallpapers/Maldrakor/contents/3840x1920.jpg"
          else
            "share/wallpapers/Tree/contents/images/Tree.jpg";
        description = ''
          Wallpaper path inside themePackage, used for the login greeter.
        '';
        type = lib.types.str;
      };
    };
  };
  config = lib.mkIf anyEdition {
    services.desktopManager.plasma6 = {
      enable = gDefault true;
      enableQt5Integration = gDefault false;
    };

    services.displayManager = {
      enable = gDefault true;
      plasma-login-manager.enable = gDefault true;
    };

    environment.plasma6.excludePackages = gDefault (
      lib.optionals (!config.garuda.flatpak.enable) (with pkgs.kdePackages; [ discover ])
      ++ (with pkgs.kdePackages; [
        elisa
        khelpcenter
        kwin-x11
        oxygen
        plasma-browser-integration
        plasma-keyboard
        qtvirtualkeyboard
        spectacle
      ])
    );

    environment.systemPackages = [
      (pkgs.kdePackages.spectacle.override { tesseractLanguages = cfg.ocrLang; })
    ]
    ++ gExcludableArray config "defaultpackages" (
      with pkgs;
      [
        ffmpegthumbnailer
        kdePackages.applet-window-buttons6
        kdePackages.kdegraphics-thumbnailers
        kdePackages.kimageformats
        kdePackages.kio-admin
        kdePackages.qtstyleplugin-kvantum
        plasma-panel-colorizer
        plasma-plugin-blurredwallpaper
        resvg
        sshfs
        vlc
        xdg-desktop-portal
      ]
    );

    environment.etc."plasmalogin.conf.d/${config.garuda.system.type}.conf".text = ''
      [Greeter][Wallpaper][org.kde.image][General]
      Image=file://${cfg.themePackage}/${cfg.wallpaper}
    '';

    garuda.create-home.skel = gDefault "${gGenerateSkel pkgs "${cfg.themePackage}/skel"
      config.garuda.system.type
    }";

    fonts = {
      enableDefaultPackages = gDefault false;
      packages =
        with pkgs;
        gExcludableArray config "defaultpackages" [
          cfg.fontPackage
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
            cfg.fontName
            "Noto Fonts Emoji"
          ];
          serif = gDefault [
            cfg.fontName
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

    qt = {
      enable = true;
      platformTheme = "kde";
    };

    services.orca.enable = gDefault false;

    # Fix "the name ca.desrt.dconf was not provided by any .service files"
    # https://nix-community.github.io/home-manager/index.html
    programs.dconf.enable = gDefault true;

    programs = {
      kdeconnect.enable = gDefault true;
      partition-manager.enable = gDefault true;
    };

    environment.variables = {
      ALSOFT_DRIVERS = gDefault "pipewire";
      MOZ_USE_XINPUT2 = gDefault "1";
      SDL_AUDIODRIVER = gDefault "pipewire";
    };

    xdg.portal.extraPortals = gDefault [ pkgs.xdg-desktop-portal-gtk ];
  };
}
