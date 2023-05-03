{ config, lib, flake-inputs, ... }:
let
  cfg = config.garuda.networking;
in
with lib;
{
  options = {
    garuda.networking.enable =
      mkOption {
        default = true;
        description = ''
          This enables networking related settings for Garuda.
        '';
      };
  };
  config = {
    networking = mkDefault {
      nameservers = [ "1.1.1.1" "1.0.0.1" ];
      networkmanager = {
        enable = true;
        unmanaged = [ "lo" "docker0" ];
        wifi.backend = "iwd";
      };
      # Enable nftables instead of iptables
      nftables.enable = true;
      # Disable non-NetworkManager
      useDHCP = false;
    };

    # Enable wireless database
    hardware.wirelessRegulatoryDatabase = true;

    # Enable BBR & cake
    boot.kernelModules = [ "tcp_bbr" ];
    boot.kernel.sysctl = {
      "net.core.default_qdisc" = "cake";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fin_timeout" = 5;
    };
  };
}
