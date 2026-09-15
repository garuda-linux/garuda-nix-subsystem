{
  config,
  garuda-lib,
  lib,
  ...
}:
with garuda-lib;
let
  cfg = config.garuda.preset;
in
{
  options.garuda.preset = lib.mkOption {
    default = null;
    type = lib.types.nullOr (
      lib.types.enum [
        "desktop"
        "laptop"
        "server"
        "handheld"
      ]
    );
    description = "Preset mapping to performance/powersave, ssh, firewall.";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg == "desktop") {
      garuda.performance-tweaks.enable = gDefault true;
      services.openssh.enable = gDefault false;
    })
    (lib.mkIf (cfg == "laptop") {
      garuda.powersave-tweaks.enable = gDefault true;
      garuda.hardware.laptop.enable = gDefault true;
      services.power-profiles-daemon.enable = lib.mkOverride 900 true;
    })
    (lib.mkIf (cfg == "server") {
      garuda.system.type = lib.mkOverride 900 "headless";
      services.openssh.enable = gDefault true;
      networking.firewall.enable = gDefault true;
    })
    (lib.mkIf (cfg == "handheld") {
      garuda.gaming.enable = gDefault true;
      garuda.performance-tweaks.enable = gDefault true;
    })
  ];
}
