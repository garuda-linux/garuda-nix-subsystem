{ config, lib, pkgs, garuda-lib, ... }:
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
          If enabled, Garuda Linux's dr460nized config will be used.
        '';
        type = lib.types.bool;
      };
      themePackage = lib.mkOption {
        default = pkgs.dr460nized-kde-theme;
        description = ''
          The theme package to use.
        '';
        type = lib.types.package;
        example = pkgs.libsForQt5.breeze-qt5;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    garuda.system.type = "dr460nized";

    services.desktopManager.plasma6.enable = gDefault true;
    services.desktopManager.plasma6.enableQt5Integration = gDefault false;

    services.displayManager = {
      enable = gDefault true;
      sddm = {
        autoNumlock = gDefault true;
        enable = gDefault true;
        settings = {
          General = {
            CursorTheme = gDefault "Sweet-cursors";
            Font = gDefault "Fira Sans";
          };
        };
        theme = gDefault "Dr460nized";

        wayland.enable = gDefault false;
      };
    };

    services.xserver = {
      enable = gDefault true;
    };

    environment.plasma6.excludePackages = with pkgs; [
      # Pulls in 600 mb worth of mbrola (via espeak), which is a bit silly
      kdePackages.okular
      kdePackages.oxygen
      kdePackages.plasma-browser-integration
    ];

    # Fix "the name ca.desrt.dconf was not provided by any .service files"
    # https://nix-community.github.io/home-manager/index.html
    programs.dconf.enable = true;

    # Define the default fonts Fira Sans & Jetbrains Mono Nerd Fonts
    fonts = {
      enableDefaultPackages = gDefault false;
      packages = with pkgs;
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
          monospace = gDefault [ "JetBrains Mono Nerd Font" "Noto Fonts Emoji" ];
          sansSerif = gDefault [ "Fira" "Noto Fonts Emoji" ];
          serif = gDefault [ "Fira" "Noto Fonts Emoji" ];
          emoji = gDefault [ "Noto Fonts Emoji" ];
        };
        # This fixes emoji stuff
        enable = gDefault true;
      };
      fontDir = {
        enable = gDefault true;
        decompressFonts = gDefault true;
      };
    };

    # Dr460nized-specific home-manager configuration
    garuda.home-manager.modules = gExcludableArray config "home-manager-modules" [
      (lib.mkBefore ./dotfiles.nix)
    ];

    # These need to be enabled for complete functionality
    programs = {
      direnv = {
        enable = gDefault true;
        silent = gDefault true;
      };
      kdeconnect.enable = gDefault true;
      partition-manager.enable = gDefault true;
    };

    # Enable Kvantum for theming & Pipewire
    environment.variables = {
      ALSOFT_DRIVERS = gDefault "pipewire";
      GTK_THEME = gDefault "Sweet-Dark";
      MOZ_USE_XINPUT2 = gDefault "1";
      QT_STYLE_OVERRIDE = gDefault "kvantum";
      SDL_AUDIODRIVER = gDefault "pipewire";
    };

    # Add xdg-desktop-portal-gtk for Wayland GTK apps (font issues etc.)
    xdg.portal.extraPortals = gDefault [ pkgs.xdg-desktop-portal-gtk ];

    # Use the Dr460nized theme as default /etc/skel folder
    garuda.create-home.skel = gDefault "${gGenerateSkel pkgs "${cfg.themePackage}/skel" "dr460nized"}";
  };
}
