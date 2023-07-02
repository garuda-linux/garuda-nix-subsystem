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

  # Discard blocks that are not in use by the filesystem
  services.fstrim.enable = gDefault true;

  # Firmware updater for machine hardware
  services.fwupd.enable = gDefault true;

  # Limit systemd journal size
  services.journald.extraConfig = ''
    SystemMaxUse=50M
    RuntimeMaxUse=10M
  '';

  # Enable locating files via locate
  services.locate = {
    enable = gDefault true;
    localuser = null;
    interval = "hourly";
    locate = pkgs.plocate;
  };

  # Power profiles daemon
  services.power-profiles-daemon.enable = gDefault true;

  # Docker
  virtualisation.docker = {
    autoPrune.enable = gDefault true;
    autoPrune.flags = [ "-a" ];
  };
}
