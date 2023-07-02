{ config, lib, ... }:
let
  cfg = config.garuda.chaotic-nyx.cache;
in
with lib;
{
  options = {
    garuda.chaotic-nyx.cache.enable =
      mkOption {
        default = true;
        type = types.bool;
        description = ''
          If set to true, Chaotic's Nyx will have its binary cache automatically enabled and managed.
        '';
      };
  };
  config = {
    chaotic.nyx.cache.enable = cfg.enable;
  };
}
