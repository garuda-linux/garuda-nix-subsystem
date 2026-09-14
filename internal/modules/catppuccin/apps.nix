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
        easyeffects
        firedragon-bin
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
