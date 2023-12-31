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
        example = true;
        description = mdDoc ''
          If set to true, this module will enable a few performance tweaks.
        '';
      };
    cachyos-kernel = mkOption
      {
        default = false;
        type = types.bool;
        example = true;
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

    # 90% ZRAM as swap
    zramSwap = mkIf cfg.enable {
      algorithm = "zstd";
      enable = gDefault true;
      memoryPercent = 90;
    };

    # Fedora defaults for systemd-oomd
    systemd.oomd = {
      enable = lib.mkForce true; # This is actually the default, anyways...
      enableSystemSlice = gDefault true;
      enableUserSlices = gDefault true;
    };

    # BPF-based auto-tuning of Linux system parameters
    services.bpftune.enable = gDefault true;

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
