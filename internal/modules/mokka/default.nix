{
  config,
  lib,
  garuda-lib,
  ...
}:
with garuda-lib;
let
  cfg = config.garuda.mokka;
in
{
  imports = [ ./apps.nix ];
  options = {
    garuda.mokka = {
      enable = lib.mkOption {
        default = false;
        example = true;
        description = ''
          Mokka edition: calm dark Plasma 6 desktop in the Catppuccin
          Mocha palette, with matching login theme, apps and defaults.
          Mutually exclusive with garuda.dr460nized.
        '';
        type = lib.types.bool;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.garuda.dr460nized.enable;
        message = "garuda.mokka and garuda.dr460nized cannot be enabled at the same time.";
      }
      {
        assertion = !config.garuda.catppuccin.enable;
        message = "garuda.mokka and garuda.catppuccin cannot be enabled at the same time.";
      }
    ];

    garuda.system.type = "mokka";

    garuda.home-manager.modules = gExcludableArray config "home-manager-modules" [
      (lib.mkBefore ./metafiles.nix)
    ];

    environment.variables = {
      GTK_THEME = gDefault "Catppuccin-Mocha-Standard-Mauve-Dark";
      QT_STYLE_OVERRIDE = gDefault "kvantum";
    };

    catppuccin = {
      autoEnable = gDefault false;
      enable = gDefault false;
    };
  };
}
