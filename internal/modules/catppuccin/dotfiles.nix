{ hmModule }:
{ pkgs, ... }:
{
  imports = [
    ./metafiles.nix
    hmModule
  ];

  catppuccin = {
    cursors.enable = true;
    enable = true;
  };

  gtk = {
    enable = true;
    gtk2.force = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-button-images = true;
      gtk-cursor-blink = true;
      gtk-decoration-layout = "close,minimize,maximize:";
      gtk-enable-animations = true;
      gtk-menu-images = true;
      gtk-modules = "appmenu-gtk-module:colorreload-gtk-module";
      gtk-primary-button-warps-slider = true;
      gtk-shell-shows-menubar = 1;
      gtk-sound-theme-name = "ocean";
      gtk-toolbar-style = 3;
      gtk-xft-dpi = 98304;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-cursor-blink = true;
      gtk-decoration-layout = "close,minimize,maximize:";
      gtk-enable-animations = true;
      gtk-primary-button-warps-slider = true;
      gtk-sound-theme-name = "ocean";
      gtk-xft-dpi = 98304;
    };
    font = {
      name = "Inter";
      size = 10;
    };
    theme = {
      package = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        variant = "mocha";
      };
      name = "catppuccin-mocha-mauve-standard";
    };
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    size = 24;
    x11.defaultCursor = "catppuccin-mocha-mauve-cursors";
  };

  dconf.enable = true;
  xdg.enable = true;
}
