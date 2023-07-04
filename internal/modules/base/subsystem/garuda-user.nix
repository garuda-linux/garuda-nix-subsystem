{ config, lib, ... }:
with lib;
let
  cfg = config.garuda.subsystem.imported-users;
  submoduleOptions = {
    options = {
      home = mkOption { type = types.str; };
      passwordHash = mkOption { type = types.str; };
      uid = mkOption { type = types.int; };
      wheel = mkOption { type = types.bool; };
    };
  };
in
{
  options.garuda.subsystem.imported-users = {
    createHome = mkOption {
      type = types.bool;
      default = true;
      internal = true;
    };
    users = mkOption {
      type = types.attrsOf (types.submodule submoduleOptions);
      default = { };
    };
    enable = mkOption {
      type = types.bool;
      default = true;
    };
    shared-home = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
      uuid = mkOption {
        type = types.str;
      };
    };
  };

  config = lib.mkIf (cfg.enable && config.garuda.subsystem.enable) {
    users.users = mapAttrs
      (name: value: {
        isNormalUser = true;
        inherit (value) uid;
        initialHashedPassword = value.passwordHash;
        createHome = cfg.createHome || cfg.shared-home.enable;
        extraGroups = lib.mkIf value.wheel [ "wheel" ];
      })
      cfg.users;
  };
}
