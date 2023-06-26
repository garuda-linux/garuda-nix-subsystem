{ config, lib, ... }:
with lib;
let
  cfg = config.garuda.subsystem.imported-users;
  submoduleOptions = {
    options = {
      passwordHash = mkOption { type = types.str; };
      uid = mkOption { type = types.int; };
      home = mkOption { type = types.str; };
      wheel = mkOption { type = types.bool; };
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
        inherit (value) uid;
        initialHashedPassword = value.passwordHash;
        inherit (cfg) createHome;
        extraGroups = lib.mkIf value.wheel [ "wheel" ];
      })
      cfg.users;
  };
}
