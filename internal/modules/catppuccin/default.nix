{ inputs, ... }: { config
                 , lib
                 , pkgs
                 , garuda-lib
                 , ...
                 }:
with garuda-lib;
let
  catppuccin-settings = pkgs.stdenvNoCC.mkDerivation {
    pname = "catppuccin-settings";
    version = "0.0.2";
    src = ./src;
    installPhase = ''
      runHook preInstall
      install -d $out/skel
      cp -ar skel/{.config,.local} $out/skel
      install -d $out/share
      cp -ar share/{konsole,plasma,wallpapers} $out/share
      runHook postInstall
    '';
    meta = with lib; {
      description = "Garuda NixOS flake Catppuccin NixOS configs";
      homepage = "https://garudalinux.org";
      license = licenses.gpl3Only;
      maintainers = [ maintainers.dr460nf1r3 ];
      platforms = platforms.all;
    };
  };
  cfg = config.garuda.catppuccin;
in
{
  imports = [
    ./apps.nix
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
        default = pkgs.catppuccin-kde;
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
        catppuccin = {
          assertQt6Sddm = true;
          enable = true;
          font = "Fira Sans";
        };
        enable = gDefault true;
        wayland.enable = gDefault true;
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
    garuda.home-manager.modules = [
      (import ./dotfiles.nix {
        hmModule = inputs.catppuccin.homeManagerModules.catppuccin;
      })
    ];

    # Use the custom Catppuccin settings package as default /etc/skel folder
    garuda.create-home.skel = gDefault "${gGenerateSkel pkgs "${catppuccin-settings}/skel" "catppuccin"}";

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
      MOZ_USE_XINPUT2 = gDefault "1";
      SDL_AUDIODRIVER = gDefault "pipewire";
    };

    # Plymouth theme
    boot.plymouth = {
      theme = "catppuccin-mocha";
      themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
    };

    # Theming
    catppuccin.enable = true;
    console.catppuccin.enable = true;

    # Add xdg-desktop-portal-gtk for Wayland GTK apps (font issues etc.)
    xdg.portal.extraPortals = gDefault [ pkgs.xdg-desktop-portal-gtk ];
  };
}
