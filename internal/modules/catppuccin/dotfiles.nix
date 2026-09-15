{ hmModule }:
{
  pkgs,
  garuda-lib,
  ...
}:
with garuda-lib;
{
  imports = [
    ./metafiles.nix
    hmModule
  ];

  catppuccin = {
    autoEnable = gDefault true;
    cursors.enable = gDefault true;
    enable = gDefault true;
  };

  gtk = {
    enable = gDefault true;
    gtk2.force = gDefault true;
    gtk3.extraConfig = gDefault {
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
    gtk4.extraConfig = gDefault {
      gtk-application-prefer-dark-theme = true;
      gtk-cursor-blink = true;
      gtk-decoration-layout = "close,minimize,maximize:";
      gtk-enable-animations = true;
      gtk-primary-button-warps-slider = true;
      gtk-sound-theme-name = "ocean";
      gtk-xft-dpi = 98304;
    };
    font = gDefault {
      name = "Inter";
      size = 10;
    };
    theme = gDefault {
      package = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        variant = "mocha";
      };
      name = "catppuccin-mocha-mauve-standard";
    };
  };

  # Not gDefault due to catppuccin/nix upstream otherwise overriding,
  # which produces a warning about missing enable option with config set.
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    size = 24;
    x11.defaultCursor = "catppuccin-mocha-mauve-cursors";
  };

  dconf.enable = gDefault true;
  xdg.enable = gDefault true;
}
