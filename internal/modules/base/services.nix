{ config
, garuda-lib
, pkgs
, lib
, ...
}:
let
  cfg = config.garuda;
in
with garuda-lib;
{
  options.garuda.btrfs-maintenance = {
    enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = ''
        Installs and enables some filesystem optimizations for BTRFS.
      '';
    };
    deduplication = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = ''
        Enables the beesd service to deduplicate files in the background.
      '';
    };
    uuid = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = ''
        The UUID of the BTRFS filesystem to deduplicate.
      '';
    };
  };

  config = {
    # Bluetooth
    hardware.bluetooth.enable = gDefault true;

    # Handle ACPI events
    services = {
      acpid.enable = gDefault true;
      avahi = {
        enable = gDefault true;
        nssmdns = gDefault true;
      };
    };

    # Filesystem deduplication in the background
    services.beesd.filesystems = lib.mkIf (cfg.btrfs-maintenance.deduplication && cfg.btrfs-maintenance.enable && cfg.btrfs-maintenance.uuid != null) {
      root = {
        extraOptions = [ "--loadavg-target" "1.0" ];
        hashTableSizeMB = 2048;
        spec = "UUID=${cfg.btrfs-maintenance.uuid}";
        verbosity = "crit";
      };
    };

    # Enable regular scrubbing of BTRFS filesystems
    services.btrfs.autoScrub.enable = lib.mkIf cfg.btrfs-maintenance.enable true;

    # Discard blocks that are not in use by the filesystem
    services.fstrim.enable = gDefault true;

    # Firmware updater for machine hardware
    services.fwupd.enable = gDefault true;

    # Limit systemd journal size
    services.journald.extraConfig = ''
      SystemMaxUse=500M
      RuntimeMaxUse=10M
    '';

    # Enable locating files via locate
    services.locate = {
      enable = gDefault true;
      localuser = null;
      interval = "hourly";
      package = pkgs.plocate;
    };

    # Power profiles daemon
    services.power-profiles-daemon.enable = gDefault true;

    # Docker
    virtualisation.docker = {
      autoPrune.enable = gDefault true;
      autoPrune.flags = [ "-a" ];
    };
  };
}
