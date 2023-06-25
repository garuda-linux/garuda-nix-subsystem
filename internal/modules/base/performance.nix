{ config
, garuda-lib
, lib
, pkgs
, ...
}:
with lib;
with garuda-lib;
let
  cfg = config.garuda.performance-tweaks;
in
{
  options.garuda.performance-tweaks = {
    enable = mkOption
      {
        default = false;
        type = types.bool;
        description = mdDoc ''
          If set to true, this module will enable a few performance tweaks.
        '';
      };
    cachyos-kernel = mkOption
      {
        default = false;
        type = types.bool;
        description = mdDoc ''
          If set to true, the subsystem will use the linux_cachyos kernel.
        '';
      };
  };

  config = {
    # Automatically tune nice levels
    services.ananicy = mkIf cfg.enable {
      enable = gDefault true;
      package = pkgs.ananicy-cpp;
    };

    # Supply fitting rules for ananicy-cpp 
    environment.systemPackages = with pkgs; mkIf cfg.enable [
      ananicy-cpp-rules
    ];

    # Get notifications about earlyoom actions
    services.systembus-notify.enable = mkIf cfg.enable (gDefault true);

    # 90% ZRAM as swap
    zramSwap = mkIf cfg.enable {
      algorithm = "zstd";
      enable = gDefault true;
      memoryPercent = 90;
    };

    # Earlyoom to prevent OOM situations
    services.earlyoom = mkIf cfg.enable {
      enable = gDefault true;
      enableNotifications = true;
      freeMemThreshold = 5;
    };

    ## A few other kernel tweaks
    boot.kernel.sysctl = mkIf cfg.enable {
      "kernel.nmi_watchdog" = 0;
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;
      "net.core.rmem_max" = 2500000;
      "vm.max_map_count" = 16777216;
      "vm.swappiness" = 60;
    };

    # Use the Linux_cachyos kernel
    boot.kernelPackages = mkIf cfg.cachyos-kernel pkgs.linuxPackages_cachyos;
  };
}
