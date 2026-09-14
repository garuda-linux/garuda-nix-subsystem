{ lib, ... }:
{
  users = {
    mutableUsers = false;
    users = {
      garuda = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        password = "garuda";
      };
      root.password = "garuda";
    };
  };

  garuda.mokka.enable = true;

  services.qemuGuest.enable = lib.mkForce true;

  console.keyMap = "de";
  time.timeZone = "Europe/Berlin";

  virtualisation.vmVariant = {
    virtualisation = {
      cores = 4;
      memorySize = 3072;
    };
  };

  system.stateVersion = "26.11";
}
