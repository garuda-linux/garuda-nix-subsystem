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
        firedragon-bin
        easyeffects
        sweet-nova
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
