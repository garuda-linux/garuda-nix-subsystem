{ inputs, ... }: { config
                 , lib
                 , pkgs
                 , garuda-lib
                 , ...
                 }:
with garuda-lib;
let
  catppuccin-kde =
    (pkgs.catppuccin-kde.override {
      accents = [ "maroon" ];
      flavour = [ "mocha" ];
      winDecStyles = [ "classic" ];
    });
  cfg = config.garuda.catppuccin;
in
{
  imports = [
    #./apps.nix
    inputs.catppuccin.nixosModules.catppuccin
  ];

  options = {
    garuda.catppuccin = {
      enable = lib.mkOption {
        default = false;
        example = true;
        description = ''
          If enabled, Garuda Linux's Catppuccin config will be used.
        '';
        type = lib.types.bool;
      };
      themePackage = lib.mkOption {
        default = catppuccin-kde;
        description = ''
          The theme package to use.
        '';
        type = lib.types.package;
        example = pkgs.libsForQt5.breeze-qt5;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    garuda.system.type = "catppuccin";

    services.desktopManager.plasma6.enable = gDefault true;

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

    environment.plasma6.excludePackages = with pkgs; [
      # Pulls in 600 mb worth of mbrola (via espeak), which is a bit silly
      okular
      oxygen
      plasma-browser-integration
    ];

    # Allow GTK applications to show an appmenu on KDE
    chaotic.appmenu-gtk3-module.enable = gDefault true;

    # Fix "the name ca.desrt.dconf was not provided by any .service files"
    # https://nix-community.github.io/home-manager/index.html
    programs.dconf.enable = true;

    # Define the default fonts Fira Sans & Jetbrains Mono Nerd Fonts
    fonts = {
      enableDefaultPackages = gDefault false;
      packages = with pkgs;
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
          monospace = gDefault [ "JetBrains Mono Nerd Font" "Noto Fonts Emoji" ];
          sansSerif = gDefault [ "Fira" "Noto Fonts Emoji" ];
          serif = gDefault [ "Fira" "Noto Fonts Emoji" ];
          emoji = gDefault [ "Noto Fonts Emoji" ];
        };
        enable = gDefault true;
      };
      fontDir = {
        enable = gDefault true;
        decompressFonts = gDefault true;
      };
    };

    # Catppuccin-specific home-manager configuration
    # garuda.home-manager.modules = gExcludableArray config "home-manager-configs" [ ./dotfiles.nix ];

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
      GTK_THEME = gDefault "Catppuccin-Mocha-Standard-Maroon-Dark";
      MOZ_USE_XINPUT2 = gDefault "1";
      SDL_AUDIODRIVER = gDefault "pipewire";
    };

    # Add xdg-desktop-portal-gtk for Wayland GTK apps (font issues etc.)
    xdg.portal.extraPortals = gDefault [ pkgs.xdg-desktop-portal-gtk ];

    # Use the Catppuccin theme as default /etc/skel folder
    garuda.create-home.skel = gDefault "${gGenerateSkel pkgs "${cfg.themePackage}/skel" "catpuccin"}";
  };
}
