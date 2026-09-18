{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.garuda.impermanence;

  rollbackScript = device: ''
    mkdir -p /mnt
    mount -o subvol=/ ${device} /mnt

    btrfs subvolume list -o /mnt/root |
    cut -f9 -d' ' |
    while read subvolume; do
      echo "deleting /$subvolume subvolume..."
      btrfs subvolume delete "/mnt/$subvolume"
    done &&
    echo "deleting /root subvolume..." &&
    btrfs subvolume delete /mnt/root

    echo "restoring blank /root subvolume..."
    btrfs subvolume snapshot /mnt/root-blank /mnt/root

    umount /mnt
  '';
in
{
  config = lib.mkIf cfg.enable {
    fileSystems."/" = lib.mkIf cfg.tmpfsRoot (
      lib.mkForce {
        device = "none";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=25%"
          "mode=755"
        ];
      }
    );

    boot.initrd = {
      supportedFilesystems = [ "btrfs" ];
      systemd.enable = true;

      systemd.services.rollback = lib.mkIf (!cfg.tmpfsRoot) {
        description = "Rollback btrfs root subvolume";
        wantedBy = [ "initrd.target" ];
        after = [ "initrd-root-device.target" ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        path = with pkgs; [
          btrfs-progs
          coreutils
          util-linux
        ];
        script = rollbackScript cfg.device;
      };
    };

    assertions = [
      {
        assertion = cfg.tmpfsRoot || lib.attrByPath [ "/" "fsType" ] "" config.fileSystems == "btrfs";
        message = ''
          garuda.impermanence: / is not btrfs, so rollbacks cannot work.
          Either install with a btrfs-impermanence partition schema, or set
          garuda.impermanence.tmpfsRoot = true.
        '';
      }
    ];
  };
}
