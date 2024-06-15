{ hmModule }: { lib, pkgs, ... }:
{
  imports = [
    ./metafiles.nix
    hmModule
  ];

  # Base configs (default is mocha flavor)
  catppuccin = {
    accent = "maroon";
    enable = true;
  };

  # Complete theming
  programs = {
    bat = {
      catppuccin.enable = true;
      config.theme = lib.mkForce "Catppuccin Mocha";
    };
    btop = {
      catppuccin.enable = true;
      settings.color_theme = lib.mkForce "catppuccin_mocha.theme";
    };
    fish.catppuccin.enable = true;
    micro = {
      catppuccin.enable = true;
      settings.colorscheme = lib.mkForce "catppuccin-mocha";
    };
    starship.catppuccin.enable = true;
    tmux.catppuccin.enable = true;
  };

  # GTK theming (values generated by KDE)
  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-button-images = true;
      gtk-decoration-layout = "close,maximize,minimize:";
      gtk-enable-animations = true;
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-menu-images = true;
      gtk-modules = "appmenu-gtk-module:colorreload-gtk-module";
      gtk-primary-button-warps-slider = true;
      gtk-shell-shows-menubar = 1;
      gtk-sound-theme-name = "ocean";
      gtk-theme-name = "Catppuccin-Mocha-Standard-Maroon-Dark";
      gtk-toolbar-style = 3;
      gtk-xft-dpi = 98304;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = "close,maximize,minimize:";
      gtk-enable-animations = true;
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-primary-button-warps-slider = true;
      gtk-sound-theme-name = "ocean";
      gtk-theme-name = "Catppuccin-Mocha-Standard-Maroon-Dark";
      gtk-xft-dpi = 98304;
    };
    font = {
      name = "Fira Sans";
      size = 10;
    };
  };

  # This is needed to get the cursor on apps like Webstorm
  home.pointerCursor = {
    gtk.enable = true;
    name = "catppuccin-mocha-maroon-cursors";
    size = 24;
    package = pkgs.catppuccin-cursors;
    x11.defaultCursor = "catppuccin-mocha-maroon-cursors";
  };

  # Compatibility for GNOME apps
  dconf.enable = true;

  # Compatibility for XDG stuff
  xdg.enable = true;
}
