{ lib, pkgs, ... }:
{
  users.mutableUsers = false;

  users.users.root.password = "garuda";
  users.users.garuda = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "garuda";
    createHome = false;
  };

  garuda.dr460nized.enable = true;

  services.qemuGuest.enable = lib.mkForce true;

  console.keyMap = "de";
  services.xserver.layout = "de";

  security.pam.services.systemd-user.makeHomeDir = true;
  # /etc/skel equivalent
  security.pam.makeHomeDir.skelDirectory = "${pkgs.dr460nized-kde-theme}/skel";

  time.timezone = "Europe/Berlin";

  system.stateVersion = "23.05";
}
