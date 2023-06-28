{ config, lib, garuda-lib, ... }:
with lib;
with garuda-lib;
let
  cfg = config.garuda.subsystem;
  subsystem = builtins.fromJSON (builtins.readFile cfg.config);
in
{
  imports = [
    ./garuda-user.nix
  ];

  options.garuda.subsystem = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    config = mkOption {
      type = types.path;
    };
    useGrub = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader = mkIf cfg.useGrub {
      grub = {
        device = "nodev";
      };
    };
    networking.hostName = gDefault subsystem.hostname;
    garuda.subsystem.imported-users.users = builtins.listToAttrs (builtins.map
      (x: {
        name = x.name;
        value = {
          passwordHash = x.hashed_password;
          uid = x.uid;
          home = x.home;
          wheel = x.wheel;
        };
      })
      subsystem.v1.users);
    time.timeZone = mkIf (subsystem.v1 ? timezone) (gDefault subsystem.v1.timezone);
    console.keyMap = mkIf (subsystem.v1 ? keymap) (gDefault subsystem.v1.keymap);
    services.xserver.layout = mkIf (subsystem.v1 ? keymap) (gDefault subsystem.v1.keymap);
    i18n = {
      defaultLocale = mkIf (subsystem.v1 ? locale && subsystem.v1.locale ? LANG) (gDefault subsystem.v1.locale.LANG);
      extraLocaleSettings = mkIf (subsystem.v1 ? locale) (lib.mapAttrs (name: value: gDefault value) (subsystem.v1.locale));
    };
  };
}
