{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.garuda.subsystem;
  users = config.garuda.subsystem.imported-users;
in
{
  config.systemd = lib.mkIf (cfg.enable && users.shared-home.enable) {
    mounts = [
      {
        what = "UUID=${users.shared-home.uuid}";
        options = "subvol=@home,compress=zstd,noatime,noauto,nofail";
        where = "/run/garuda/subsystem/sharedhome/new";
        wantedBy = lib.mkForce [ ];
      }
    ]
    ++ (builtins.concatLists (
      (lib.attrsets.mapAttrsToList (
        name: _value: [
          # Mount the .config
          {
            what = "/run/garuda/subsystem/sharedhome/old/${name}/.config";
            where = "/run/garuda/subsystem/sharedhome/new/${name}/.config";
            options = "bind,noauto,nofail";
            unitConfig = {
              RequiresMountsFor = [ "/run/garuda/subsystem/sharedhome/new" ];
            };
            requires = [ "garuda-sharedhome-${name}-init.service" ];
            after = [ "garuda-sharedhome-${name}-init.service" ];
            wantedBy = lib.mkForce [ ];
          }
          # Mount the .local
          {
            what = "/run/garuda/subsystem/sharedhome/old/${name}/.local";
            where = "/run/garuda/subsystem/sharedhome/new/${name}/.local";
            options = "bind,noauto,nofail";
            unitConfig = {
              RequiresMountsFor = [ "/run/garuda/subsystem/sharedhome/new" ];
            };
            requires = [ "garuda-sharedhome-${name}-init.service" ];
            after = [ "garuda-sharedhome-${name}-init.service" ];
            wantedBy = lib.mkForce [ ];
          }
          # Mount the .cache
          {
            what = "/run/garuda/subsystem/sharedhome/old/${name}/.cache";
            where = "/run/garuda/subsystem/sharedhome/new/${name}/.cache";
            options = "bind,noauto,nofail";
            unitConfig = {
              RequiresMountsFor = [ "/run/garuda/subsystem/sharedhome/new" ];
            };
            requires = [ "garuda-sharedhome-${name}-init.service" ];
            after = [ "garuda-sharedhome-${name}-init.service" ];
            wantedBy = lib.mkForce [ ];
          }
          # Mount the new home directory to /home/$name
          {
            what = "/run/garuda/subsystem/sharedhome/new/${name}";
            where = "/home/${name}";
            options = "rbind,noauto,nofail";
            before = [ "multi-user.target" ];
            wantedBy = [ "multi-user.target" ];
            unitConfig = {
              RequiresMountsFor = [
                "/run/garuda/subsystem/sharedhome/new/${name}/.config"
                "/run/garuda/subsystem/sharedhome/new/${name}/.local"
                "/run/garuda/subsystem/sharedhome/new/${name}/.cache"
              ];
            };
          }
        ]
      ))
        users.users
    ));
    services = lib.mkMerge (
      lib.attrsets.mapAttrsToList (name: _value: {
        "garuda-sharedhome-${name}-init" = {
          unitConfig = {
            RequiresMountsFor = [
              "/run/garuda/subsystem/sharedhome/new"
            ];
          };
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -e
            # Mount the old home directory to /run/garuda/subsystem/sharedhome/old/$name
            "${pkgs.coreutils}/bin/mkdir" -p "/run/garuda/subsystem/sharedhome/old/${name}"
            "${pkgs.util-linux}/bin/mount" --bind --make-private "/home/${name}" "/run/garuda/subsystem/sharedhome/old/${name}"
          '';
          wantedBy = lib.mkForce [ ];
          after = [ "create-homedirs.service" ];
        };
      }) users.users
    );
  };
}
