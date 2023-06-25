{ config, lib, pkgs, garuda-lib, ... }:
with garuda-lib;
let
  cfg = config.garuda.dr460nized;
  to_import = [ import ./apps.nix import ./misc.nix ];
in
{
  imports = [ ./apps.nix ./misc.nix ];
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
    services.xserver.enable = gDefault true;
    services.xserver.displayManager.sddm.enable = gDefault true;
    services.xserver.desktopManager.plasma5.enable = gDefault true;

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

    # Enable Kvantum for theming
    environment.variables = {
      ALSOFT_DRIVERS = gDefault "pipewire";
      MOZ_USE_XINPUT2 = gDefault "1";
      QT_STYLE_OVERRIDE = gDefault "kvantum";
      SDL_AUDIODRIVER = gDefault "pipewire";
    };

    # Default theme
    security.pam.services.systemd-user.makeHomeDir = gDefault true;
    security.pam.makeHomeDir.skelDirectory = gDefault
      "${pkgs.dr460nized-kde-theme}/skel";
    # Make sure that the home directories are not created by something that is not pam
    garuda.subsystem.imported-users.createHome = gDefault false;
  };
}
