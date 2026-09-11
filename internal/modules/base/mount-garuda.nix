{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.garuda.garuda-chroot;
in
{
  options.garuda.garuda-chroot = {
    enable = mkOption {
      default = false;
      type = types.bool;
      example = true;
      description = mdDoc ''
        Enables mounting of the Garuda Linux root partition.
      '';
    };
    root = mkOption {
      default = "/var/lib/machines/garuda";
      type = types.str;
      example = "/mnt/ssd/garuda";
      description = mdDoc ''
        Specifies where the Garuda Linux root partition should be mounted
      '';
    };
    root-uuid = mkOption {
      default = null;
      type = types.str;
      example = "f498b189-79c7-40e4-859e-fadc1496ee8e";
      description = mdDoc ''
        Provide the UUID of the Garuda root partition
      '';
    };
    boot-uuid = mkOption {
      default = null;
      type = types.str;
      example = "D9CB-2B11";
      description = mdDoc ''
        Provide the UUID of the Garuda boot partition
      '';
    };
    user = mkOption {
      default = null;
      type = types.str;
      example = "garuda";
      description = mdDoc ''
        The default user of the Garuda / NixOS subsystem
      '';
    };
    nvidia = mkOption {
      default = false;
      type = types.bool;
      example = true;
      description = mdDoc ''
        Bind the NVIDIA device nodes into the container (host has an NVIDIA GPU).
      '';
    };
    pipewire = mkOption {
      default = true;
      type = types.bool;
      example = false;
      description = mdDoc ''
        Bind the host PipeWire socket into the container for native audio.
      '';
    };
    wayland = mkOption {
      default = true;
      type = types.bool;
      example = true;
      description = mdDoc ''
        Bind the host Wayland socket into the container (xhost/X11 alone
        does nothing on a Wayland session).
      '';
    };
    waylandSocket = mkOption {
      default = "wayland-0";
      type = types.str;
      example = "wayland-1";
      description = mdDoc ''
        Name of the host Wayland socket under /run/user/1000 to bind.
      '';
    };
  };

  config = mkIf cfg.enable {
    fileSystems."${cfg.root}" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "compress=zstd"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/home" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/root" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@root"
        "compress=zstd"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/srv" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@srv"
        "compress=zstd"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/var/cache" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@cache"
        "compress=zstd"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/var/log" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@log"
        "compress=zstd"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/var/tmp" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@tmp"
        "compress=zstd"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/boot/efi" = {
      device = "/dev/disk/by-uuid/${cfg.boot-uuid}";
      fsType = "vfat";
      options = [ "noatime" ];
    };

    # One-click access to the Garuda root from GUI file managers
    systemd.tmpfiles.rules = lib.mkIf (cfg.user != null) [
      "L+ /home/${cfg.user}/Garuda - - - - ${cfg.root}"
    ];

    # Be able to run the same installation in systemd-nspawn
    systemd.targets.machines.enable = true;
    systemd.nspawn."garuda" = {
      enable = true;
      execConfig = {
        Boot = "yes";
        Capability = "all";
        PrivateUsers = 0;
        ResolvConf = "copy-host";
      };
      filesConfig = {
        Bind = [
          "/dev/dri/card0"
          "/dev/dri/renderD128"
          "/dev/input"
          "/dev/shm"
          "/dev/tty"
          "/dev/tty0"
          "/dev/tty1"
          "/dev/tty2"
          "/dev/video0"
          "/run/udev:/run/udev"
          "/sys/class/input"
        ]
        ++ lib.optionals cfg.nvidia [
          "/dev/nvidia0"
          "/dev/nvidia-caps"
          "/dev/nvidiactl"
          "/dev/nvidia-modeset"
          "/dev/nvidia-uvm"
          "/dev/nvidia-uvm-tools"
        ]
        ++ lib.optionals cfg.pipewire [
          "/run/user/1000/pipewire-0"
        ]
        ++ lib.optionals cfg.wayland [
          "/run/user/1000/${cfg.waylandSocket}"
        ];
      };
      networkConfig = {
        Private = false;
      };
    };
    systemd.services."systemd-nspawn@garuda" = {
      enable = true;
      environment = {
        SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
      }
      // lib.optionalAttrs cfg.wayland {
        WAYLAND_DISPLAY = cfg.waylandSocket;
      };
      overrideStrategy = "asDropin";
      wantedBy = [ "machines.target" ];
    };

    # Easy alias for starting the machine
    # Programs & global config
    programs = {
      bash.shellAliases = {
        "grun" = "sudo systemctl start systemd-nspawn@garuda; sudo machinectl login garuda";
      };
      fish.shellAbbrs = {
        "grun" = "sudo systemctl start systemd-nspawn@garuda; sudo machinectl login garuda";
      };
    };
  };
}
