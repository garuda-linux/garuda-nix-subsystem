{
  config,
  garuda-lib,
  lib,
  ...
}:
let
  cfg = config.garuda.gaming;
in
with garuda-lib;
{
  options.garuda.gaming = {
    enable = lib.mkOption {
      default = false;
      description = ''
        Installs and enables some gaming packages and services.
      '';
      example = true;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    cachyos.settings = {
      enable = gDefault true;
      enableGaming = gDefault true;
    };

    programs.gamemode.enable = gDefault true;

    programs.steam = {
      enable = gDefault true;
      gamescopeSession.enable = gDefault true;
    };
  };
}
