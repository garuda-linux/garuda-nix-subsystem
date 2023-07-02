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
    };
    users = mkOption {
      type = types.attrsOf (types.submodule submoduleOptions);
      default = { };
    };
    enable = mkOption {
      type = types.bool;
      default = true;
    };
    shared-home = mkOption {
      type = types.bool;
      default = false;
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

    # Mount Garuda's home partition to our Nix subvolume
    fileSystems."/home" = lib.mkIf cfg.shared-home
      {
        device = "/dev/disk/by-uuid/${cfg.uuid}";
        fsType = "btrfs";
        options = [ "subvol=@home" "compress=zstd" "noatime" ];
      };
  };
}
