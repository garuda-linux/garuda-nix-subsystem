{ config
, garuda-lib
, lib
, pkgs
, ...
}:
with lib;
with garuda-lib;
let
  cfg = config.garuda.locales;
in
{
  options.garuda.locales = {
    defaultLocale = mkOption
      {
        default = "en_GB.UTF-8";
        type = types.str;
        description = mdDoc ''
          Sets the default locale for the Garuda Nix subsystem.
        '';
      };
    defaultUnits = mkOption
      {
        default = "de_DE.UTF-8";
        type = types.str;
        description = mdDoc ''
          Sets the default units for the Garuda Nix subsystem.
        '';
      };
    keymap = mkOption
      {
        default = "de";
        type = types.str;
        description = mdDoc ''
          Sets the default keymap for the Garuda Nix subsystem.
        '';
      };
    timezone = mkOption
      {
        default = "Europe/Berlin";
        type = types.str;
        description = mdDoc ''
          Sets the default timezone for the Garuda Nix subsystem.
        '';
      };
  };

  config = {
    # Timezone
    time = {
      hardwareClockInLocalTime = gDefault true;
      timeZone = cfg.timezone;
    };

    # Common locale settings
    i18n = {
      defaultLocale = cfg.defaultLocale;

      extraLocaleSettings = {
        LANG = cfg.defaultLocale;
        LC_COLLATE = cfg.defaultUnits;
        LC_CTYPE = cfg.defaultUnits;
        LC_MESSAGES = cfg.defaultUnits;

        LC_ADDRESS = cfg.defaultUnits;
        LC_IDENTIFICATION = cfg.defaultUnits;
        LC_MEASUREMENT = cfg.defaultUnits;
        LC_MONETARY = cfg.defaultUnits;
        LC_NAME = cfg.defaultUnits;
        LC_NUMERIC = cfg.defaultUnits;
        LC_PAPER = cfg.defaultUnits;
        LC_TELEPHONE = cfg.defaultUnits;
        LC_TIME = cfg.defaultUnits;
      };
    };

    # Console font
    console = {
      font = "${pkgs.terminus_font}/share/consolefonts/ter-120n.psf.gz";
      keyMap = cfg.keymap;
    };

    # X11 keyboard layout
    services.xserver.layout = cfg.keymap;
  };
}

