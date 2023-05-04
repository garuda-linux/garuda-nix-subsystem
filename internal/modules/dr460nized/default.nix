_: { config, lib, pkgs, ... }:
let
  cfg = config.garuda.dr460nized;
in
{
  # To-do: move those to config {} ?
  imports = [
    ./apps.nix
    ./misc.nix
    ./shells.nix
  ];

  options = {
    garuda.dr460nized.enable =
      lib.mkOption {
        default = true;
        description = ''
          If enabled, Garuda Linux's dr460nized config will be used.
        '';
      };
  };
  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;

    environment.plasma5.excludePackages = with pkgs; [
      # Pulls in 600 mb worth of mbrola (via espeak), which is a bit silly
      okular
      oxygen
      plasma-browser-integration
    ];

    # Allow GTK applications to show an appmenu on KDE
    chaotic.appmenu-gtk3-module.enable = true;

    # Define the default fonts Fira Sans & Jetbrains Mono Nerd Fonts
    fonts = {
      fonts = with pkgs; [
        fira
        (nerdfonts.override {
          fonts = [
            "JetBrainsMono"
          ];
        })
        noto-fonts
        noto-fonts-emoji
      ];
      fontconfig = {
        cache32Bit = true;
        defaultFonts = {
          monospace = [ "JetBrains Mono Nerd Font" "Noto Fonts Emoji" ];
          sansSerif = [ "Fira" "Noto Fonts Emoji" ];
          serif = [ "Fira" "Noto Fonts Emoji" ];
        };
        # This fixes emoji stuff
        enable = true;
      };
      fontDir = {
        enable = true;
        decompressFonts = true;
      };
    };

    # These need to be enabled for complete functionality
    programs = {
      kdeconnect.enable = true;
      partition-manager.enable = true;
    };

    # Enable Kvantum for theming
    environment.variables = {
      ALSOFT_DRIVERS = "pipewire";
      MOZ_USE_XINPUT2 = "1";
      QT_STYLE_OVERRIDE = "kvantum";
      SDL_AUDIODRIVER = "pipewire";
    };

    # GPU acceleration
    hardware.opengl = {
      driSupport = true;
      driSupport32Bit = true;
      enable = true;
    };
  };
}
