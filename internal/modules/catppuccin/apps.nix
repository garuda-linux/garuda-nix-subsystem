{
  lib,
  pkgs,
  garuda-lib,
  config,
  ...
}:
import ../theme/generic-apps.nix
  {
    getCfg = cfg: cfg.garuda.catppuccin;
    themePackages =
      pkgs: with pkgs; [
        applet-window-title
        (catppuccin.override {
          accent = "mauve";
          variant = "mocha";
          themeList = [
            "bat"
            "btop"
            "kvantum"
          ];
        })
        catppuccin-cursors.mochaMauve
        (catppuccin-kde.override {
          accents = [ "mauve" ];
          flavour = [ "mocha" ];
          winDecStyles = [ "classic" ];
        })
        (catppuccin-papirus-folders.override {
          accent = "mauve";
          flavor = "mocha";
        })
        ffmpegthumbnailer
        firedragon-bin
        jamesdsp
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
