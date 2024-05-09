{ config
, garuda-lib
, lib
, ...
}:
with garuda-lib;
let
  cfg = config.garuda.hardware;
in
with garuda-lib;
{
  options = {
    garuda.hardware.enable =
      lib.mkOption {
        default = true;
        type = lib.types.bool;
        description = ''
          If set to true, reasonable defaults for hardware will be set.
        '';
      };
  };

  config = lib.mkIf cfg.enable {
    # Microcode and firmware updates
    hardware = {
      cpu = {
        amd.updateMicrocode = gDefault true;
        intel.updateMicrocode = gDefault true;
      };
      enableRedistributableFirmware = gDefault true;
      opengl = {
        driSupport = gDefault config.garuda.system.isGui;
        driSupport32Bit = gDefault config.garuda.system.isGui;
        enable = gDefault config.garuda.system.isGui;
      };
    };
  };
}
