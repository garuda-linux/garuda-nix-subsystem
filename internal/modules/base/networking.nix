{ config, lib, garuda-lib, ... }:
let
  cfg = config.garuda.networking;
in
with lib;
with garuda-lib;
{
  options = {
    garuda.networking = {
      enable = mkOption {
        default = true;
        type = types.bool;
        example = true;
        description = ''
          If set to true, reasonable defaults for networking will be set.
        '';
      };
      iwd = mkOption {
        default = true;
        type = types.bool;
        example = true;
        description = ''
          If set to true, iwd will be used as the wireless backend.
        '';
      };
    };
  };
  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager = {
        enable = gDefault true;
        unmanaged = [ "lo" "docker0" "virbr0" ];
        wifi = {
          backend = gDefault (if cfg.iwd then "iwd" else "wpa_supplicant");
          powersave = gDefault false;
        };
      };
      # Disable non-NetworkManager
      useDHCP = gDefault false;
      wireless.iwd = lib.mkIf cfg.iwd {
        enable = gDefault true;
        settings = {
          General.AddressRandomization = gDefault "once";
          General.AddressRandomizationRange = gDefault "full";
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
