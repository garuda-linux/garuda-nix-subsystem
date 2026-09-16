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
  cfg = config.garuda.performance-tweaks;
in
{
  options.garuda.performance-tweaks = {
    enable = mkOption {
      default = false;
      type = types.bool;
      example = true;
      description = ''
        If set to true, this module will enable Garuda's powersave tweaks.
        Conflicts with garuda.powersave-tweaks, only one may be enabled.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !cfg.enable || !config.garuda.powersave-tweaks.enable;
        message = "garuda.performance-tweaks and garuda.powersave-tweaks cannot be enabled at the same time.";
      }
    ];

    services.ananicy = mkIf cfg.enable {
      enable = gDefault true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos_git;
    };

    services.irqbalance.enable = mkIf cfg.enable (gDefault true);

    powerManagement.cpuFreqGovernor = mkIf cfg.enable (gDefault "performance");

    boot.extraModprobeConfig = mkIf cfg.enable "options amdgpu ppfeaturemask=0xffffffff";

    systemd.tmpfiles.rules = mkIf cfg.enable [
      "w /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference - - - - performance"
      "w /sys/module/pcie_aspm/parameters/policy - - - - performance"
      "w /sys/class/drm/card0/device/power_dpm_state - - - - performance"
    ];

    environment.systemPackages = [ pkgs.hdparm ];
    services.udev.extraRules = mkIf cfg.enable ''
      KERNEL=="card0", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_state}="performance"
      KERNEL=="card0", SUBSYSTEM=="drm", DRIVERS=="radeon", ATTR{device/power_dpm_state}="performance"
      ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="max_performance"
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
      ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", RUN+="${pkgs.hdparm}/bin/hdparm -B 254 -S 0 /dev/%k"
    '';

    zramSwap = mkIf cfg.enable {
      algorithm = "zstd";
      enable = gDefault true;
      memoryPercent = 90;
    };

    # Fedora enables these options by default. See the 10-oomd-* files here:
    # https://src.fedoraproject.org/rpms/systemd/tree/acb90c49c42276b06375a66c73673ac3510255
    systemd.oomd = {
      enable = gDefault true;
      enableRootSlice = gDefault true;
      enableUserSlices = gDefault true;
      enableSystemSlice = gDefault true;
      settings.OOM = {
        "DefaultMemoryPressureDurationSec" = gDefault "20s";
      };
    };

    services.bpftune.enable = gDefault true;

    boot.kernel.sysctl = mkIf cfg.enable {
      "kernel.nmi_watchdog" = 0;
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;
      "net.core.rmem_max" = 2500000;
      "vm.max_map_count" = 16777216;
      # ZRAM is relatively cheap, prefer swap
      "vm.swappiness" = 180;
      # ZRAM is in memory, no need to readahead
      "vm.page-cluster" = 0;
    };
  };
}
