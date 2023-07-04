{ config, lib, pkgs, ... }:
let
  cfg = config.garuda.subsystem;
  users = config.garuda.subsystem.imported-users;
in
{
  config.systemd = lib.mkIf (cfg.enable && users.shared-home.enable) ({
    mounts = [{
      what = "UUID=${users.shared-home.uuid}";
      options = "subvol=@home,compress=zstd,noatime,noauto";
      where = "/run/garuda/sharedhome/new";
      after = [ "multi-user.target" ];
    }] ++ (builtins.concatLists (
      (lib.attrsets.mapAttrsToList
        (name: value: [
          # Mount the .config 
          {
            what = "/run/garuda/sharedhome/old/${name}/.config";
            where = "/run/garuda/sharedhome/new/${name}/.config";
            options = "bind,noauto";
            unitConfig = {
              RequiresMountsFor = [ "/run/garuda/sharedhome/new"];
            };
            requires = [ "garuda-sharedhome-${name}-init.service" ];
            after = [ "garuda-sharedhome-${name}-init.service" ];
          }
          # Mount the .local
          {
            what = "/run/garuda/sharedhome/old/${name}/.local";
            where = "/run/garuda/sharedhome/new/${name}/.local";
            options = "bind,noauto";
            unitConfig = {
              RequiresMountsFor = [ "/run/garuda/sharedhome/new"];
            };
            requires = [ "garuda-sharedhome-${name}-init.service" ];
            after = [ "garuda-sharedhome-${name}-init.service" ];
          }
          # Mount the .cache
          {
            what = "/run/garuda/sharedhome/old/${name}/.cache";
            where = "/run/garuda/sharedhome/new/${name}/.cache";
            options = "bind,noauto";
            unitConfig = {
              RequiresMountsFor = [ "/run/garuda/sharedhome/new"];
            };
            requires = [ "garuda-sharedhome-${name}-init.service" ];
            after = [ "garuda-sharedhome-${name}-init.service" ];
          }
          # Mount the new home directory to /home/$name
          {
            what = "/run/garuda/sharedhome/new/${name}";
            where = "/home/${name}";
            options = "bind,noauto";
            unitConfig = {
              RequiresMountsFor = [
                "/run/garuda/sharedhome/new/${name}/.cache"
                "/run/garuda/sharedhome/new/${name}/.config"
                "/run/garuda/sharedhome/new/${name}/.local"
              ];
            };
          }
        ])) users.users
    ));
    services = (lib.mkMerge (
      (lib.attrsets.mapAttrsToList
        (name: value: {
          "garuda-sharedhome-${name}-init" = {
            serviceConfig.Type = "oneshot";
            script = ''
              set -e
              # Mount the old home directory to /run/garuda/sharedhome/$name
              "${pkgs.coreutils}/bin/mkdir" -p "/run/garuda/sharedhome/old/${name}"
              if ! "${pkgs.util-linux}/bin/mountpoint" -q "/run/garuda/sharedhome/old/${name}"; then
                "${pkgs.util-linux}/bin/mount" --bind "/home/${name}" "/run/garuda/sharedhome/old/${name}"
              fi
              ${lib.optionalString (users.createHome) ''
                "${pkgs.linux-pam}/bin/mkhomedir_helper" "${name}"
              ''}
            '';
          };
        })
        users.users)
    ));
    automounts = lib.attrsets.mapAttrsToList
      (name: value: {
        where = "/home/${name}";
        automountConfig.DirectoryMode = "0700";
        enable = true;
        before = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
      })
      users.users;
  });
}
