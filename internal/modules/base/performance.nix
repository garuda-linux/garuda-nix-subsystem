{ config
, garuda-lib
, lib
, pkgs
, ...
}:
with lib;
with garuda-lib; let
  cfg = config.garuda.performance-tweaks;
in
{
  options.garuda.performance-tweaks = {
    enable =
      mkOption
        {
          default = false;
          type = types.bool;
          example = true;
          description = mdDoc ''
            If set to true, this module will enable a few performance tweaks.
          '';
        };
    cachyos-kernel =
      mkOption
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
      rulesProvider = pkgs.ananicy-cpp-rules;
    };

    # 90% ZRAM as swap
    zramSwap = mkIf cfg.enable {
      algorithm = "zstd";
      enable = gDefault true;
      memoryPercent = 90;
    };

    # Fedora enables these options by default. See the 10-oomd-* files here:
    # https://src.fedoraproject.org/rpms/systemd/tree/acb90c49c42276b06375a66c73673ac3510255
    systemd.oomd = {
      enable = lib.mkForce true;
      enableRootSlice = gDefault true;
      enableUserSlices = gDefault true;
      enableSystemSlice = gDefault true;
      extraConfig = {
        "DefaultMemoryPressureDurationSec" = "20s";
      };
    };

    # BPF-based auto-tuning of Linux system parameters
    services.bpftune.enable = gDefault true;

    ## A few other kernel tweaks
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

    # Use the Linux_cachyos kernel
    boot.kernelPackages = mkIf cfg.cachyos-kernel pkgs.linuxPackages_cachyos;
  };
}
