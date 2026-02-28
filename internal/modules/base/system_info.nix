{ config, lib, ... }:
{
  options = {
    garuda.system = {
      isGui = lib.mkOption {
        type = lib.types.bool;
        internal = true;
      };
      isHeadless = lib.mkOption {
        type = lib.types.bool;
        internal = true;
      };
      type = lib.mkOption {
        type = lib.types.str;
        default = "headless";
        internal = true;
      };
    };
  };
  config = {
    garuda.system = {
      isGui = if config.garuda.system.type != "headless" then true else false;
      isHeadless = if config.garuda.system.type == "headless" then true else false;
    };
  };
}
