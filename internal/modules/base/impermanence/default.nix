{ lib, ... }:
let
  impSrc = fetchTarball {
    url = "https://github.com/nix-community/impermanence/archive/7b1d382faf603b6d264f58627330f9faa5cba149.tar.gz";
    sha256 = "sha256-03+JxvzmfwRu+5JafM0DLbxgHttOQZkUtDWBmeUkN8Y=";
  };
  impMod = import (impSrc + "/nixos.nix");
in
{
  imports = [
    ./rollback.nix
    ./persistence.nix
    ./apps.nix
    impMod
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
