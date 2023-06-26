{ config, lib, garuda-lib, ... }:
with lib;
with garuda-lib;
let
  cfg = config.garuda.subsystem;
  subsystem = builtins.fromJSON (builtins.readFile cfg.config);
in
{
  imports = [
    ./garuda-user.nix
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
        name = x.name;
        value = {
          passwordHash = x.hashed_password;
          uid = x.uid;
          home = x.home;
          wheel = x.wheel;
        };
      })
      subsystem.v1.users);
  };
}
