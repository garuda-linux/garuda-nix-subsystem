{
  config,
  lib,
  garuda-lib,
  settings,
  ...
}:
with lib;
with garuda-lib;
let
  cfg = config.garuda.subsystem;
in
{
  imports = [
    ./imported-users.nix
    ./shared-home.nix
  ];

  options.garuda.subsystem = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Run this NixOS install as a subsystem inside Garuda Linux:
        it derives certain settings from the Garuda installation,
        imports the host's users, shares their home directories
        and mounts the Garuda root filesystem for cross-system access.
      '';
    };
    useGrub = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Install GRUB (device "nodev") so the Garuda host bootloader can
        chainload this system. Disable when the host bootloader already
        handles booting or another loader is used.
      '';
    };
    import-networkmanager = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Bind-mount the Garuda host's NetworkManager system-connections
        into this system, so Wi-Fi and VPN profiles are shared instead
        of configured twice.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader = mkIf cfg.useGrub {
      grub = {
        device = "nodev";
      };
    };
    garuda.subsystem.imported-users.users = builtins.listToAttrs (
      builtins.map (x: {
        inherit (x) name;
        value = {
          passwordHash = x.hashed_password;
          inherit (x) uid;
          inherit (x) home;
          inherit (x) wheel;
        };
      }) settings.users
    );
    garuda.subsystem.imported-users.shared-home.uuid = settings.uuid;
    systemd.mounts = [
      {
        what = "UUID=${settings.uuid}";
        options = "subvol=@,compress=zstd,noatime,noauto,nofail";
        where = "/run/garuda/subsystem/root";
        wantedBy = lib.mkForce [ ];
      }
    ]
    ++ lib.lists.optional cfg.import-networkmanager {
      what = "/run/garuda/subsystem/root/etc/NetworkManager/system-connections";
      options = "bind,noauto,nofail";
      where = "/etc/NetworkManager/system-connections";
      before = [ "NetworkManager.service" ];
      wantedBy = lib.mkForce [ "NetworkManager.service" ];
    };
  };
}
