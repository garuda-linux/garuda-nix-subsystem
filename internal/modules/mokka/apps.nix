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
        kde-rounded-corners
        firedragon-catppuccin-bin
        mokka-kde-theme
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
