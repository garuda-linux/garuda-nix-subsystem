{ config, lib, garuda-lib, ... }:
with lib;
with garuda-lib;
let
  cfg = config.garuda.subsystem;
  subsystem = builtins.fromJSON (builtins.readFile cfg.config);
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
    config = mkOption {
      type = types.path;
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
    networking.hostName = gDefault subsystem.hostname;
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
      subsystem.v1.users);
    garuda.subsystem.imported-users.shared-home.uuid = subsystem.v1.uuid;
    time.timeZone = mkIf (subsystem.v1 ? timezone) (gDefault subsystem.v1.timezone);
    console.keyMap = mkIf (subsystem.v1 ? keymap) (gDefault subsystem.v1.keymap);
    services.xserver.layout = mkIf (subsystem.v1 ? keymap) (gDefault subsystem.v1.keymap);
    i18n = {
      defaultLocale = mkIf (subsystem.v1 ? locale && subsystem.v1.locale ? LANG) (gDefault subsystem.v1.locale.LANG);
      extraLocaleSettings = mkIf (subsystem.v1 ? locale) (lib.mapAttrs (_name: gDefault) subsystem.v1.locale);
    };
    systemd.mounts = [{
      what = "UUID=${subsystem.v1.uuid}";
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

    virtualisation.vmware.guest.enable = lib.mkIf (subsystem.v1 ? hardware) (gDefault (subsystem.v1.hardware.virt == "vmware"));
    virtualisation.virtualbox.guest.enable = lib.mkIf (subsystem.v1 ? hardware) (gDefault (subsystem.v1.hardware.virt == "oracle"));
  };
}
