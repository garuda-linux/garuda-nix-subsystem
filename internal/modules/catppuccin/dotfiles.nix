{ hmModule }:
{ pkgs, lib, ... }:
{
  imports = [
    ./metafiles.nix
    hmModule
  ];

  catppuccin = {
    autoEnable = lib.mkDefault true;
    cursors.enable = lib.mkDefault true;
    enable = lib.mkDefault true;
  };

  gtk = {
    enable = lib.mkDefault true;
    gtk2.force = lib.mkDefault true;
    gtk3.extraConfig = lib.mkDefault {
      gtk-application-prefer-dark-theme = true;
      gtk-button-images = true;
      gtk-cursor-blink = true;
      gtk-decoration-layout = "close,minimize,maximize:";
      gtk-enable-animations = true;
      gtk-menu-images = true;
      gtk-modules = "colorreload-gtk-module";
      gtk-primary-button-warps-slider = true;
      gtk-shell-shows-menubar = 1;
      gtk-sound-theme-name = "ocean";
      gtk-toolbar-style = 3;
      gtk-xft-dpi = 98304;
    };
    gtk4.extraConfig = lib.mkDefault {
      gtk-application-prefer-dark-theme = true;
      gtk-cursor-blink = true;
      gtk-decoration-layout = "close,minimize,maximize:";
      gtk-enable-animations = true;
      gtk-primary-button-warps-slider = true;
      gtk-sound-theme-name = "ocean";
      gtk-xft-dpi = 98304;
    };
    font = lib.mkDefault {
      name = "Inter";
      size = 10;
    };
    theme = lib.mkDefault {
      package = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        variant = "mocha";
      };
      name = "catppuccin-mocha-mauve-standard";
    };
  };

  home.pointerCursor = lib.mkDefault {
    enable = true;
    gtk.enable = true;
    size = 24;
    x11.defaultCursor = "catppuccin-mocha-mauve-cursors";
  };

  dconf.enable = lib.mkDefault true;
  xdg.enable = lib.mkDefault true;
}
