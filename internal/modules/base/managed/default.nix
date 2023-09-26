{ config, lib, garuda-lib, pkgs, ... }:
with lib;
with garuda-lib;
let
  cfg = config.garuda.managed;
  managed = builtins.fromJSON (builtins.readFile cfg.config);
  unmerged_settings = managed.v2;
  settings = attrsets.recursiveUpdate (attrsets.recursiveUpdate unmerged_settings.auto (unmerged_settings.host or { })) (unmerged_settings.user or { });
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

  config = mkIf (cfg.config != null) {
    networking.hostName = gDefault managed.hostname;
    virtualisation.vmware.guest.enable = lib.mkIf (settings ? hardware) (gDefault (settings.hardware.virt == "vmware"));
    virtualisation.virtualbox.guest.enable = lib.mkIf (settings ? hardware) (gDefault (settings.hardware.virt == "oracle"));
    time.timeZone = mkIf (settings ? timezone) (gDefault settings.timezone);
    console.keyMap = mkIf (settings ? keymap) (gDefault settings.keymap);
    services.xserver.layout = mkIf (settings ? keymap) (gDefault settings.keymap);
    i18n = {
      defaultLocale = mkIf (settings ? locale && settings.locale ? LANG) (gDefault settings.locale.LANG);
      extraLocaleSettings = mkIf (settings ? locale) (lib.mapAttrs (_name: gDefault) settings.locale);
    };

    environment.systemPackages = mkIf (settings ? extrapackages) (
      lists.remove null (map (pkg: pkgs."${pkg}" or (warn "${builtins.toString cfg.config}: Package "${pkg}" does not exist" null)) settings.extrapackages)
    );
  };
}
