{ lib, ... }:
{
  imports = [
    ./rollback.nix
    ./persistence.nix
    ./apps.nix
  ];

  options.garuda.impermanence = {
    enable = lib.mkEnableOption "impermanence";
    tmpfsRoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use tmpfs for / instead of rolling back a btrfs subvolume.";
    };
    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/disk/by-label/nixos";
      description = "Btrfs device holding the root/root-blank subvolumes.";
    };
    persistentUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Users whose .config/.local/share persist.";
    };
  };
}
