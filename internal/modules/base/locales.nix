{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.garuda.locales;
  de = "de_DE.UTF-8";
  defaultLocale = "en_US.UTF-8";
  terminus-variant = "116n";
in
{
  options.garuda.locales = {
    enable = mkOption
      {
        default = true;
        type = types.bool;
        description = mdDoc ''
          Whether the operating system be having a default set of locales set.
        '';
      };
  };

  config = mkIf cfg.enable {
    # Timezone
    time = {
      hardwareClockInLocalTime = true;
      timeZone = "Europe/Berlin";
    };

    # Common locale settings
    i18n = {
      inherit defaultLocale;

      extraLocaleSettings = {
        LANG = defaultLocale;
        LC_COLLATE = defaultLocale;
        LC_CTYPE = defaultLocale;
        LC_MESSAGES = defaultLocale;

        LC_ADDRESS = de;
        LC_IDENTIFICATION = de;
        LC_MEASUREMENT = de;
        LC_MONETARY = de;
        LC_NAME = de;
        LC_NUMERIC = de;
        LC_PAPER = de;
        LC_TELEPHONE = de;
        LC_TIME = de;
      };

      supportedLocales = [
        "de_DE.UTF-8/UTF-8"
        "en_GB.UTF-8/UTF-8"
        "en_US.UTF-8/UTF-8"
      ];
    };

    # Console font
    console = mkIf cfg.enable {
      font = "${pkgs.terminus_font}/share/consolefonts/ter-${terminus-variant}.psf.gz";
      keyMap = "de";
    };

    # X11 keyboard layout
    services.xserver = mkIf cfg.enable {
      layout = "de";
      xkbVariant = "";
    };
  };
}
