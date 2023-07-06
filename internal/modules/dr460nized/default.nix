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
        description = ''
          If enabled, Garuda Linux's dr460nized config will be used.
        '';
      };
      themePackage = lib.mkOption {
        default = pkgs.dr460nized-kde-theme;
        description = ''
          The theme package to use.
        '';
      };
    };
  };
  config = lib.mkIf cfg.enable {
    services.xserver = {
      desktopManager.plasma5.enable = gDefault true;
      displayManager = {
        sddm = {
          autoNumlock = gDefault true;
          enable = gDefault true;
          settings = {
            General = {
              CursorTheme = gDefault "Sweet-cursors";
              Font = gDefault "Fira Sans";
            };
          };
          theme = gDefault "Sweet";
        };
      };
      enable = gDefault true;
      excludePackages = [ pkgs.xterm ];
    };

    environment.plasma5.excludePackages = with pkgs; [
      # Pulls in 600 mb worth of mbrola (via espeak), which is a bit silly
      okular
      oxygen
      plasma-browser-integration
    ];

    # Allow GTK applications to show an appmenu on KDE
    chaotic.appmenu-gtk3-module.enable = gDefault true;

    # Define the default fonts Fira Sans & Jetbrains Mono Nerd Fonts
    fonts = {
      fonts = with pkgs;
        gExcludableArray config "defaultpackages" [
          fira
          (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
          noto-fonts
          noto-fonts-cjk
          noto-fonts-emoji
        ];
      fontconfig = {
        cache32Bit = gDefault true;
        defaultFonts = {
          monospace =
            gDefault [ "JetBrains Mono Nerd Font" "Noto Fonts Emoji" ];
          sansSerif = gDefault [ "Fira" "Noto Fonts Emoji" ];
          serif = gDefault [ "Fira" "Noto Fonts Emoji" ];
        };
        # This fixes emoji stuff
        enable = gDefault true;
      };
      fontDir = {
        enable = gDefault true;
        decompressFonts = gDefault true;
      };
    };

    # These need to be enabled for complete functionality
    programs = {
      kdeconnect.enable = gDefault true;
      partition-manager.enable = gDefault true;
    };

    # Enable Kvantum for theming & Pipewire
    environment.variables = {
      ALSOFT_DRIVERS = gDefault "pipewire";
      MOZ_USE_XINPUT2 = gDefault "1";
      QT_STYLE_OVERRIDE = gDefault "kvantum";
      SDL_AUDIODRIVER = gDefault "pipewire";
    };

    # Set /etc/skel directory to pull theming from
    security.pam = {
      services.systemd-user.makeHomeDir = gDefault true;
      makeHomeDir.skelDirectory = gDefault "${gGenerateSkel pkgs "${pkgs.dr460nized-kde-theme}/skel" "dr460nized"}";
    };

    # Make sure that the home directories are not created by something that is not pam
    garuda.subsystem.imported-users.createHome = gDefault false;
  };
}
