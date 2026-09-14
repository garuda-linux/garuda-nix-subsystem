{
  config,
  lib,
  pkgs,
  garuda-lib,
  ...
}:
with garuda-lib;
let
  cfg = config.garuda.dr460nized;
in
{
  imports = [ ./apps.nix ];
  options = {
    garuda.dr460nized = {
      enable = lib.mkOption {
        default = false;
        example = true;
        description = ''
          Dr460nized edition: vibrant Sweet-themed Plasma 6 gaming desktop,
          with matching login theme, apps and defaults. Mutually
          exclusive with garuda.mokka.
        '';
        type = lib.types.bool;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.garuda.mokka.enable;
        message = "garuda.dr460nized and garuda.mokka cannot be enabled at the same time.";
      }
      {
        assertion = !config.garuda.catppuccin.enable;
        message = "garuda.dr460nized and garuda.catppuccin cannot be enabled at the same time.";
      }
    ];

    garuda.system.type = "dr460nized";

    garuda.kde.fontPackage = pkgs.fira;
    garuda.kde.fontName = "Fira";

    garuda.home-manager.modules = gExcludableArray config "home-manager-modules" [
      (lib.mkBefore ./metafiles.nix)
    ];

    environment.variables = {
      GTK_THEME = gDefault "Sweet-Dark";
      QT_STYLE_OVERRIDE = gDefault "kvantum";
    };

    catppuccin = {
      autoEnable = gDefault false;
      enable = gDefault false;
    };
  };
}
