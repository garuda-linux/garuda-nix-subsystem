{ garuda-lib, pkgs, ... }:
with garuda-lib;
{
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
}
