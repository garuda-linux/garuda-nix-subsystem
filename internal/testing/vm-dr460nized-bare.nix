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
  services.xserver = {
    enable = true;
    xkb.layout = "de";
  };

  # Timezone
  time.timeZone = "Europe/Berlin";

  # Enhance stability of the VM by disabling wayland
  # overriding the actual default
  services.displayManager = {
    defaultSession = "plasmax11";
    sddm.wayland.enable = lib.mkForce false;
  };

  # Virtualisation settings for running "nix run .#internal.vm"
  # This makes the VM usable
  virtualisation.vmVariant = {
    virtualisation = {
      cores = 4;
      memorySize = 3072;
    };
  };

  # Nix stuff
  system.stateVersion = "23.11";
}
