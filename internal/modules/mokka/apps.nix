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
        catppuccin-kde
        ffmpegthumbnailer
        firedragon-catppuccin-bin
        kde-rounded-corners
        kdePackages.applet-window-buttons6
        kdePackages.kdegraphics-thumbnailers
        kdePackages.kimageformats
        kdePackages.kio-admin
        kdePackages.qtstyleplugin-kvantum
        libinput-gestures
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
