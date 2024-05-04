{ hmModule }: { lib, ... }:
{
  imports = [
    ./metafiles.nix
    hmModule
  ];

  # Base configs (default is mocha flavor)
  catppuccin.enable = true;
  catppuccin.accent = "maroon";

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
      gtk-cursor-theme-name = "Catppuccin-Mocha-Maroon-Cursors";
      gtk-cursor-theme-size = 24;
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
      gtk-cursor-theme-name = "Catppuccin-Mocha-Maroon-Cursors";
      gtk-cursor-theme-size = 24;
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

  # Compatibility for GNOME apps
  dconf.enable = true;

  # Compatibility for XDG stuff
  xdg.enable = true;
}
