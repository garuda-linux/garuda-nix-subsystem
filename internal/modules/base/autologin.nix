{ config
, garuda-lib
, lib
, ...
}:
with lib;
let
  cfg = config.garuda.noSddmAutologin;
in
{
  options.garuda.noSddmAutologin = {
    enable =
      mkOption
        {
          default = false;
          type = types.bool;
          example = true;
          description = mdDoc ''
            Whether to enable autologin to desktop instead of using SDDM.
          '';
        };
    user =
      mkOption
        {
          default = null;
          type = types.string;
          example = "nixos";
          description = mdDoc ''
            The user to automatically login.
          '';
        };
    startupCommand =
      mkOption
        {
          default = null;
          type = types.string;
          example = "startplasma-wayland";
          description = mdDoc ''
            The command to be executed after login.
          '';
        };
  };

  config = lib.mkIf cfg.enable {
    services = {
      # This is going to be a device with autologin on Wayland
      # straight to desktop. No display manager and X needed.
      # It is strongly suggested to use this with full disk encryption
      # only.
      displayManager = {
        enable = lib.mkForce false;
        sddm.enable = lib.mkForce false;
      };
      getty.autologinUser = cfg.user;
      xserver.enable = lib.mkForce false;
    };

    # Needed for autologin in TTY to start the desktop session
    programs.bash.loginShellInit = ''
      if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
          exec ${cfg.startupCommand}
      fi
    '';

    # No X turns this off, so re-enable it
    gtk.iconCache.enable = garuda-lib.gDefault true;
  };
}
