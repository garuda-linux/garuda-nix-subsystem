{ config, lib, ... }:
with lib;
let
  cfg = config.garuda.subsystem;
in
{
  imports = [
    ./garuda-user.nix
  ];

  options.garuda.subsystem = {
    version = mkOption {
      type = types.int;
    };
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    useGrub = mkOption {
      type = types.bool;
      default = true;
    };
    UUID = mkOption {
      type = types.str;
    };
  };

  config = lib.mkIf (cfg.enable && cfg.version == 1) {
    boot.loader = mkIf cfg.useGrub {
      grub = {
        device = "nodev";
      };
    };
  };
}
