{
  lib,
  pkgs,
  garuda-lib,
  config,
  ...
}:
import ../theme/generic-apps.nix
  {
    getCfg = cfg: cfg.garuda.mokka;
    themePackages =
      pkgs: with pkgs; [
        catppuccin-cursors
        catppuccin-gtk
        (catppuccin.override {
          accent = "mauve";
          variant = "mocha";
          themeList = [
            "bat"
            "btop"
            "kvantum"
          ];
        })
        (catppuccin-kde.override {
          accents = [ "mauve" ];
          flavour = [ "mocha" ];
          winDecStyles = [ "classic" ];
        })
        ffmpegthumbnailer
        firedragon-catppuccin-bin
        kde-rounded-corners
        kdePackages.applet-window-buttons6
        kdePackages.kdegraphics-thumbnailers
        kdePackages.kimageformats
        kdePackages.kio-admin
        kdePackages.qtstyleplugin-kvantum
        mokka-kde-theme
        plasma-panel-colorizer
        plasma-plugin-blurredwallpaper
        resvg
        sshfs
        tela-circle-icon-theme
        vlc
        xdg-desktop-portal
      ];
  }
  {
    inherit
      lib
      pkgs
      garuda-lib
      config
      ;
  }
