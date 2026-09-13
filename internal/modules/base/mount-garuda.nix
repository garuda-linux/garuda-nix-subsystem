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
        "compress=zstd:1"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/home" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd:1"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/root" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@root"
        "compress=zstd:1"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/srv" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@srv"
        "compress=zstd:1"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/var/cache" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@cache"
        "compress=zstd:1"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/var/log" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@log"
        "compress=zstd:1"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/var/tmp" = {
      device = "/dev/disk/by-uuid/${cfg.root-uuid}";
      fsType = "btrfs";
      options = [
        "subvol=@tmp"
        "compress=zstd:1"
        "noatime"
      ];
    };
    fileSystems."${cfg.root}/boot/efi" = {
      device = "/dev/disk/by-uuid/${cfg.boot-uuid}";
      fsType = "vfat";
      options = [ "noatime" ];
    };

    systemd.tmpfiles.rules = lib.mkIf (cfg.user != null) [
      "L+ /home/${cfg.user}/Garuda - - - - ${cfg.root}"
      "z /var/lib/machines 0755 root root -"
      "z ${cfg.root} 0755 root root -"
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
          "/dev/dri"
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
        ]
        # Container logind mounts a tmpfs over /run/user/$UID at login, hiding the file binds above.
        ++ lib.optionals cfg.pipewire [
          "/run/user/1000/pipewire-0:/run/garuda-host/pipewire-0"
        ]
        ++ lib.optionals cfg.wayland [
          "/run/user/1000/${cfg.waylandSocket}:/run/garuda-host/${cfg.waylandSocket}"
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
      // lib.optionalAttrs cfg.pipewire {
        # Container logind shadows /run/user/$UID
        PIPEWIRE_RUNTIME_DIR = "/run/garuda-host";
      }
      // lib.optionalAttrs cfg.wayland {
        # Absolute path: libwayland treats values containing '/' as direct
        # socket paths, and this survives logind's /run/user tmpfs
        WAYLAND_DISPLAY = "/run/garuda-host/${cfg.waylandSocket}";
      };
      overrideStrategy = "asDropin";
      wantedBy = mkIf (!cfg.pipewire && !cfg.wayland) [ "machines.target" ];
    };

    systemd.paths."systemd-nspawn@garuda" = mkIf (cfg.pipewire || cfg.wayland) {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists =
        if cfg.wayland then "/run/user/1000/${cfg.waylandSocket}" else "/run/user/1000/pipewire-0";
    };

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
