{ config, lib, garuda-lib, settings, ... }:
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
    };
    useGrub = mkOption {
      type = types.bool;
      default = true;
    };
    import-networkmanager = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader = mkIf cfg.useGrub {
      grub = {
        device = "nodev";
      };
    };
    garuda.subsystem.imported-users.users = builtins.listToAttrs (builtins.map
      (x: {
        inherit (x) name;
        value = {
          passwordHash = x.hashed_password;
          inherit (x) uid;
          inherit (x) home;
          inherit (x) wheel;
        };
      })
      settings.users);
    garuda.subsystem.imported-users.shared-home.uuid = settings.uuid;
    systemd.mounts = [{
      what = "UUID=${settings.uuid}";
      options = "subvol=@,compress=zstd,noatime,noauto,nofail";
      where = "/run/garuda/subsystem/root";
      wantedBy = lib.mkForce [ ];
    }] ++ lib.lists.optional cfg.import-networkmanager {
      what = "/run/garuda/subsystem/root/etc/NetworkManager/system-connections";
      options = "bind,noauto,nofail";
      where = "/etc/NetworkManager/system-connections";
      before = [ "NetworkManager.service" ];
      wantedBy = lib.mkForce [ "NetworkManager.service" ];
    };
  };
}
