{
  lib,
  pkgs,
  garuda-lib,
  config,
  ...
}:
import ../theme/generic-apps.nix
  {
    getCfg = cfg: cfg.garuda.dr460nized;
    themePackages =
      pkgs: with pkgs; [
        applet-window-title
        beautyline-icons
        dr460nized-kde-theme
        ffmpegthumbnailer
        firedragon-bin
        easyeffects
        kdePackages.applet-window-buttons6
        kdePackages.kdegraphics-thumbnailers
        kdePackages.kimageformats
        kdePackages.kio-admin
        kdePackages.qtstyleplugin-kvantum
        libinput-gestures
        plasma-panel-colorizer
        plasma-plugin-blurredwallpaper
        resvg
        sshfs
        sweet-nova
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
