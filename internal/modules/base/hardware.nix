{ garuda-lib, pkgs, ... }:
with garuda-lib;
{
  # Microcode and firmware updates
  hardware = gDefault {
    cpu = {
      amd.updateMicrocode = true;
      intel.updateMicrocode = true;
    };
    enableRedistributableFirmware = true;
    opengl = {
      driSupport =  true;
      driSupport32Bit =  true;
      enable =  true;
    };
  };
}
