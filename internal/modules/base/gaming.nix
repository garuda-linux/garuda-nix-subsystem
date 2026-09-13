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
        Gaming setup: Steam (with gamescope session), GameMode, and the
        CachyOS gaming kernel/userspace settings.
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
