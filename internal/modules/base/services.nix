{ garuda-lib, pkgs, ... }:
with garuda-lib;
{
  # Bluetooth
  hardware.bluetooth.enable = gDefault true;

  # Handle ACPI events
  services.acpid.enable = gDefault true;

  # LAN discovery
  services.avahi = {
    enable = gDefault true;
    nssmdns = gDefault true;
  };

  # Ciscard blocks that are not in use by the filesystem
  services.fstrim.enable = gDefault true;

  # Firmware updater for machine hardware
  services.fwupd.enable = gDefault true;

  # Limit systemd journal size
  services.journald.extraConfig = gDefault ''
    SystemMaxUse=50M
    RuntimeMaxUse=10M
  '';

  # Enable locating files via locate
  services.locate = gDefault {
    enable = true;
    localuser = null;
    interval = "hourly";
    locate = pkgs.plocate;
  };

  # Power profiles daemon
  services.power-profiles-daemon.enable = gDefault true;

  # Docker
  virtualisation.docker = gDefault {
    autoPrune.enable = true;
    autoPrune.flags = [ "-a" ];
  };
}
