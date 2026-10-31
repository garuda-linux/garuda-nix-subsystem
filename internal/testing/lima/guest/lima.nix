# Lima support for the Garuda Nix test guests, taken from nixos-lima's lima.nix
{
  inputs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.nixos-lima.nixosModules.lima
  ];

  # Reads the Lima user data at boot and runs the guest agent
  services.lima.enable = true;
  services.openssh.enable = true;

  # A switch rewrites /etc/fstab and unmounts the Lima mounts that lima-init
  # added at boot. sysinit-reactivation.target is restarted on every switch,
  # so this restarts lima-init to add them again.
  systemd.services.lima-remount = {
    description = "Add the Lima mounts again after a switch";
    wantedBy = [ "sysinit-reactivation.target" ];
    serviceConfig.Type = "oneshot";
    script = "systemctl restart --no-block lima-init.service";
  };

  # lima-init adds the Lima user at boot, a rebuild must not remove it
  users.mutableUsers = true;
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ "@wheel" ];

  # The test source is mounted read-only and owned by the host user
  programs.git = {
    enable = true;
    config.safe.directory = [ "/mnt/src" ];
  };

  boot = {
    kernelParams = [ "console=tty0" ];
    loader.grub = {
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  fileSystems."/boot" = {
    device = lib.mkForce "/dev/vda1";
    fsType = "vfat";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
    options = [
      "noatime"
      "nodiratime"
      "discard"
    ];
  };
}
