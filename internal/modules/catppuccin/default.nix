{ inputs, ... }:
{
  config,
  lib,
  pkgs,
  garuda-lib,
  ...
}:
with garuda-lib;
let
  catppuccin-settings = pkgs.stdenvNoCC.mkDerivation {
    pname = "catppuccin-settings";
    version = "0.0.3";
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
    services.desktopManager.plasma6.enableQt5Integration = gDefault false;

    services.displayManager = {
      enable = gDefault true;
      plasma-login-manager.enable = gDefault true;
    };
    environment.etc."plasmalogin.conf.d/catppuccin.conf".text = ''
      [Greeter][Wallpaper][org.kde.image][General]
      Image=file://${catppuccin-settings}/share/wallpapers/Tree/contents/images/Tree.jpg
    '';

    environment.plasma6.excludePackages = with pkgs; [
      # Pulls in 600 mb worth of mbrola (via espeak), which is a bit silly
      kdePackages.okular
      kdePackages.oxygen
      kdePackages.plasma-browser-integration
    ];

    # Fix "the name ca.desrt.dconf was not provided by any .service files"
    # https://nix-community.github.io/home-manager/index.html
    programs.dconf.enable = true;

    # Define the default fonts Inter & Jetbrains Mono Nerd Fonts
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

    garuda.home-manager.modules = [
      (import ./dotfiles.nix {
        hmModule = inputs.catppuccin.homeModules.catppuccin;
      })
    ];

    garuda.create-home.skel = gDefault "${gGenerateSkel pkgs "${catppuccin-settings}/skel"
      "catppuccin"
    }";

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
      MOZ_USE_XINPUT2 = gDefault "1";
      SDL_AUDIODRIVER = gDefault "pipewire";
    };

    environment.systemPackages = [ catppuccin-settings ];

    boot.plymouth = {
      theme = "catppuccin-mocha";
      themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
    };

    catppuccin = {
      enable = true;
      tty.enable = true;
    };

    xdg.portal.extraPortals = gDefault [ pkgs.xdg-desktop-portal-gtk ];
  };
}
