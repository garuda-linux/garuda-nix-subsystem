{ lib, ... }: {
  users.mutableUsers = false;

  users.users.root.password = "garuda";
  users.users.garuda = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "garuda";
  };

  garuda.dr460nized.enable = true;

  services.qemuGuest.enable = lib.mkForce true;

  console.keyMap = "de";
  services.xserver.layout = "de";

  system.stateVersion = "23.05";
}
