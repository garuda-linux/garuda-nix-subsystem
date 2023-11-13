{ lib, pkgs, config, ... }:
let
  cfg = config.garuda.garuda-nix-manager;
  package_list = pkgs.writeTextFile {
    name = "package-list";
    text = builtins.toJSON (builtins.attrNames pkgs);
    destination = "/share/garuda/package-list.json";
  };
in
{
  options.garuda.garuda-nix-manager = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable garuda-nix-manager";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      package_list
    ];
  };
}
