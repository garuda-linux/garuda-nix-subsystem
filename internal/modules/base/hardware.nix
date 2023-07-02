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
        driSupport = gDefault true;
        driSupport32Bit = gDefault true;
        enable = gDefault true;
      };
    };
  };
}
