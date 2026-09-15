{
  config,
  garuda-lib,
  lib,
  pkgs,
  ...
}:
with garuda-lib;
{
  options.garuda.fonts.enable = lib.mkOption {
    default = config.garuda.system.isGui;
    type = lib.types.bool;
    description = "Reasonable fontconfig defaults.";
  };

  config = lib.mkIf config.garuda.fonts.enable {
    fonts.packages = with pkgs; [
      corefonts
      dejavu_fonts
      liberation_ttf
    ];

    fonts.fontconfig = {
      antialias = gDefault true;
      hinting.enable = gDefault true;
    };
  };
}
