{ lib, pkgs, ... }: 
let
  # use substitute-all-files to replace /usr/bin with /run/current-system/sw/bin
  dr460nized-kde-theme = pkgs.dr460nized-kde-theme.overrideAttrs (oldAttrs: {
    postPatch = ''
      find ./etc/skel -type f -exec substituteInPlace {} \;
      for file in $(find etc/skel -type f); do
        substituteInPlace $file --replace "/usr/bin" "/run/current-system/sw/bin" --replace "/usr/share" "/run/current-system/sw/share"
      done
    '';
  });
in
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
  security.pam.makeHomeDir.skelDirectory = "${dr460nized-kde-theme}/skel";

  system.stateVersion = "23.05";
}
