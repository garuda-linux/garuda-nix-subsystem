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

  # Catppuccin flavour
  garuda.catppuccin.enable = true;

  # Flip all the switches
  garuda.gaming.enable = true;
  garuda.performance-tweaks.enable = true;

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

  # Enhance stability of the VM by forcing the X11 session
  services.displayManager.defaultSession = "plasmax11";

  # Virtualisation settings for running the VM via `nix build .#internal.ci-full`
  # followed by `./result/bin/run-*-vm`
  virtualisation.vmVariant = {
    virtualisation = {
      cores = 4;
      memorySize = 3072;
    };
  };

  # Nix stuff
  system.stateVersion = "26.05";
}
