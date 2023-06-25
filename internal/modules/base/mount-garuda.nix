{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.garuda.garuda-chroot;
in
{
  options.garuda.garuda-chroot = {
    enable = mkOption
      {
        default = false;
        type = types.bool;
        description = mdDoc ''
          Enables mounting of the Garuda Linux root partition.
        '';
      };
    root = mkOption
      {
        default = "/var/lib/machines/garuda";
        type = types.str;
        description = mdDoc ''
          Specifies where the Garuda Linux root partition should be mounted
        '';
      };
    root-uuid = mkOption
      {
        default = null;
        type = types.str;
        description = mdDoc ''
          Provide the UUID of the Garuda root partition
        '';
      };
    boot-uuid = mkOption
      {
        default = "";
        type = types.str;
        description = mdDoc ''
          Provide the UUID of the Garuda boot partition
        '';
      };
    user = mkOption
      {
        default = "nico";
        type = types.str;
        description = mdDoc ''
          The default user of the Garuda / NixOS subsystem
        '';
      };
  };

  config = mkIf cfg.enable {
    fileSystems."${cfg.root}" =
      {
        device = "/dev/disk/by-label/OS";
        fsType = "btrfs";
        options = [ "subvol=@" "compress=zstd" "noatime" ];
      };
    fileSystems."${cfg.root}/home" =
      {
        device = "/dev/disk/by-label/OS";
        fsType = "btrfs";
        options = [ "subvol=@home" "compress=zstd" "noatime" ];
      };
    fileSystems."${cfg.root}/root" =
      {
        device = "/dev/disk/by-label/OS";
        fsType = "btrfs";
        options = [ "subvol=@root" "compress=zstd" "noatime" ];
      };
    fileSystems."${cfg.root}/srv" =
      {
        device = "/dev/disk/by-label/OS";
        fsType = "btrfs";
        options = [ "subvol=@srv" "compress=zstd" "noatime" ];
      };
    fileSystems."${cfg.root}/var/cache" =
      {
        device = "/dev/disk/by-label/OS";
        fsType = "btrfs";
        options = [ "subvol=@cache" "compress=zstd" "noatime" ];
      };
    fileSystems."${cfg.root}/var/log" =
      {
        device = "/dev/disk/by-label/OS";
        fsType = "btrfs";
        options = [ "subvol=@log" "compress=zstd" "noatime" ];
      };
    fileSystems."${cfg.root}/var/tmp" =
      {
        device = "/dev/disk/by-label/OS";
        fsType = "btrfs";
        options = [ "subvol=@tmp" "compress=zstd" "noatime" ];
      };
    fileSystems."${cfg.root}/boot/efi" =
      {
        device = "/dev/disk/by-uuid/5772-1FF9";
        fsType = "vfat";
        options = [ "noatime" ];
      };

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
          "/home/${cfg.user}/.Xauthority"
          "/run/udev:/run/udev"
          "/run/user/1000/pulse:/run/user/host/pulse"
          "/sys/class/input"
          "/tmp/.X11-unix"
        ];
      };
      networkConfig = {
        Private = false;
      };
    };
    systemd.services."systemd-nspawn@garuda" = {
      enable = true;
      environment = {
        DISPLAY = ":0.0";
        PULSE_SERVER = "unix:/run/user/host/pulse/native";
        SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
      };
      overrideStrategy = "asDropin";
      wantedBy = [ "machines.target" ];
    };

    # This is needed to share Xorg
    environment.systemPackages = [ pkgs.xorg.xhost ];

    # Easy alias for starting the machine
    # Programs & global config
    programs = {
      bash.shellAliases = {
        "grun" = "xhost +local:; sudo systemctl start systemd-nspawn@garuda; sudo machinectl login garuda; xhost -";
      };
      fish.shellAbbrs = {
        "grun" = "xhost +local:; sudo systemctl start systemd-nspawn@garuda; sudo machinectl login garuda; xhost -";
      };
    };
  };
}
