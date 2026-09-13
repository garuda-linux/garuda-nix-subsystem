{
  config,
  garuda-lib,
  lib,
  pkgs,
  ...
}:
with lib;
with garuda-lib;
let
  cfg = config.garuda.powersave-tweaks;
in
{
  options.garuda.powersave-tweaks = {
    enable = mkOption {
      default = false;
      type = types.bool;
      example = true;
      description = ''
        If set to true, this module will enable Garuda's powersave tweaks.
        Conflicts with garuda.performance-tweaks, only one may be enabled.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.garuda.performance-tweaks.enable;
        message = "garuda.powersave-tweaks and garuda.performance-tweaks cannot be enabled at the same time.";
      }
    ];

    powerManagement.cpuFreqGovernor = mkIf (!config.garuda.performance-tweaks.enable) (
      gDefault "powersave"
    );

    systemd.tmpfiles.rules = [
      "w /sys/devices/system/cpu/cpufreq/policy?/energy_performance_preference - - - - balance_power"
      "w /sys/module/pcie_aspm/parameters/policy - - - - powersave"
    ];

    environment.systemPackages = [ pkgs.hdparm ];
    services.udev.extraRules = ''
      SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="2", RUN+="${pkgs.systemd}/bin/systemctl suspend"
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTRS{queue/rotational}=="1", RUN+="${pkgs.hdparm}/bin/hdparm -B 127 /dev/%k"
    '';
  };
}
