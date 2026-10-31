{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages =
      lib.optionals (config.garuda.system.isGui || config.garuda.managed.config != null) [
        pkgs.garuda-update
      ]
      ++ lib.optionals (config.garuda.managed.config != null) [
        pkgs.garuda-nix-subsystem
      ];
  };
}
