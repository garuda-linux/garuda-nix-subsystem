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
        (catppuccin-gtk.override {
          accents = [ "mauve" ];
          variant = "mocha";
        })
        (catppuccin-kde.override {
          accents = [ "mauve" ];
          flavour = [ "mocha" ];
          winDecStyles = [ "classic" ];
        })
        easyeffects
        firedragon-catppuccin-bin
        tela-circle-icon-theme
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
