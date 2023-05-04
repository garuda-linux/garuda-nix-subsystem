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
          If set to true, reasonable defaults for networking will be set.
        '';
      };
  };
  config = {
    networking = mkDefault {
      networkmanager = {
        enable = true;
        unmanaged = [ "lo" "docker0" "virbr0" ];
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
