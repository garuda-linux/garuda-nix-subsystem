{ hmModule }: { pkgs, ... }:
{
  imports = [
    ./metafiles.nix
    hmModule
  ];

  # Base configs (default is mocha flavor)
  catppuccin = {
    accent = "maroon";
    enable = true;
    pointerCursor.enable = true;
  };

  # Complete theming
  programs = {
    bat = {
      catppuccin.enable = true;
    };
    bottom.catppuccin.enable = true;
    btop = {
      catppuccin.enable = true;
    };
    fish.catppuccin.enable = true;
    micro = {
      catppuccin.enable = true;
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
      gtk-decoration-layout = "close,maximize,minimize:";
      gtk-enable-animations = true;
      gtk-primary-button-warps-slider = true;
      gtk-sound-theme-name = "ocean";
      gtk-xft-dpi = 98304;
    };
    font = {
      name = "Fira Sans";
      size = 10;
    };
    theme = {
      package = pkgs.catppuccin-gtk.override {
        accents = [ "maroon" ];
        variant = "mocha";
      };
      name = "catppuccin-mocha-maroon-standard";
    };
  };

  # This is needed to get the cursor on apps like Webstorm
  home.pointerCursor = {
    gtk.enable = true;
    size = 24;
    x11.defaultCursor = "catppuccin-mocha-maroon-cursors";
  };

  # Compatibility for GNOME apps
  dconf.enable = true;

  # Compatibility for XDG stuff
  xdg.enable = true;
}
