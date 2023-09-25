{ config, lib, garuda-lib, ... }:
with lib;
with garuda-lib;
let
  cfg = config.garuda.managed;
  managed = builtins.fromJSON (builtins.readFile cfg.config);
  unmerged_settings = managed.v2;
  settings = mkMerge ((lists.optional (unmerged_settings ? user) unmerged_settings.user) ++ (lists.optional (unmerged_settings ? host) unmerged_settings.host) ++ [ unmerged_settings.auto ]);
in
{
  imports = [
    (import ./subsystem { inherit settings config lib garuda-lib; })
    (mkRenamedOptionModule [ "garuda" "subsystem" "config" ] [ "garuda" "managed" "config" ])
  ];

  options.garuda.managed = {
    config = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to the managed configuration file.
      '';
    };
  };

  config = lib.mkIf (cfg.config != null) {
    networking.hostName = gDefault subsystem.hostname;
    virtualisation.vmware.guest.enable = lib.mkIf (subsystem.v1 ? hardware) (gDefault (subsystem.v1.hardware.virt == "vmware"));
    virtualisation.virtualbox.guest.enable = lib.mkIf (subsystem.v1 ? hardware) (gDefault (subsystem.v1.hardware.virt == "oracle"));
    time.timeZone = mkIf (subsystem.v1 ? timezone) (gDefault subsystem.v1.timezone);
    console.keyMap = mkIf (subsystem.v1 ? keymap) (gDefault subsystem.v1.keymap);
    services.xserver.layout = mkIf (subsystem.v1 ? keymap) (gDefault subsystem.v1.keymap);
    i18n = {
      defaultLocale = mkIf (subsystem.v1 ? locale && subsystem.v1.locale ? LANG) (gDefault subsystem.v1.locale.LANG);
      extraLocaleSettings = mkIf (subsystem.v1 ? locale) (lib.mapAttrs (_name: gDefault) subsystem.v1.locale);
    };
  };
}
