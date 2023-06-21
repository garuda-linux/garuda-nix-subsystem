{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.garuda.subsystem.imported-users;
  submoduleOptions = {
    options = {
      passwordHash = mkOption { type = types.str; };
      uid = mkOption { type = types.int; };
    };
  };
in
{
  options.garuda.subsystem.imported-users = {
    createHome = mkOption {
      type = types.bool;
      default = true;
    };
    users = mkOption {
      type = types.attrsOf (types.submodule submoduleOptions);
      default = { };
    };
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = lib.mkIf (cfg.enable && config.garuda.subsystem.enable) {
    users.users = mapAttrs
      (name: value: {
        isNormalUser = true;
        uid = value.uid;
        initialHashedPassword = value.passwordHash;
        createHome = cfg.createHome;
      })
      cfg.users;
  };
}
