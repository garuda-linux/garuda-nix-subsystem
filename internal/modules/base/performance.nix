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
  };

  config = mkIf cfg.enable {
    # Automatically tune nice levels
    services.ananicy = gDefault {
      enable = true;
      package = pkgs.ananicy-cpp;
    };

    # Supply fitting rules for ananicy-cpp 
    environment.systemPackages = with pkgs; [
      ananicy-cpp-rules
    ];

    # Get notifications about earlyoom actions
    services.systembus-notify.enable = gDefault true;

    # 90% ZRAM as swap
    zramSwap = gDefault {
      algorithm = "zstd";
      enable = true;
      memoryPercent = 90;
    };

    # Earlyoom to prevent OOM situations
    services.earlyoom = gDefault {
      enable = true;
      enableNotifications = true;
      freeMemThreshold = 5;
    };

    # Tune the Zen kernel
    programs.cfs-zen-tweaks.enable = gDefault true;

    ## A few other kernel tweaks
    boot.kernel.sysctl = gDefault {
      "kernel.nmi_watchdog" = 0;
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;
      "net.core.rmem_max" = 2500000;
      "vm.max_map_count" = 16777216;
      "vm.swappiness" = 60;
    };
  };
}
