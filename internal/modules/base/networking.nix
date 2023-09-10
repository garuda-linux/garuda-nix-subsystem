{ config, lib, garuda-lib, ... }:
let
  cfg = config.garuda.networking;
in
with lib;
with garuda-lib;
{
  options = {
    garuda.networking.enable =
      mkOption {
        default = true;
        type = types.bool;
        description = ''
          If set to true, reasonable defaults for networking will be set.
        '';
      };
  };
  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager = {
        enable = gDefault true;
        unmanaged = [ "lo" "docker0" "virbr0" ];
        wifi = {
          backend = "iwd";
          powersave = gDefault false;
        };
      };
      # Disable non-NetworkManager
      useDHCP = gDefault false;
      wireless.iwd = {
        enable = gDefault true;
        settings = {
          General.AddressRandomization = "once";
          General.AddressRandomizationRange = "full";
        };
      };
    };

    # Enable wireless database
    hardware.wirelessRegulatoryDatabase = gDefault true;

    # Enable BBR & cake
    boot.kernelModules = [ "tcp_bbr" ];
    boot.kernel.sysctl = {
      "net.core.default_qdisc" = "cake";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fin_timeout" = 5;
    };
  };
}
