{ lib, ... }:
{
  # Only testing users
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

  # Dr460nized flavour
  garuda.dr460nized.enable = true;

  # Gets run via QEMU
  services.qemuGuest.enable = lib.mkForce true;

  # Some locale settings
  console.keyMap = "de";
  services.xserver.xkb.layout = "de";
  time.timeZone = "Europe/Berlin";

  system.stateVersion = "23.11";
}
