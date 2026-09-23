{
  config,
  garuda-lib,
  lib,
  pkgs,
  ...
}:
with garuda-lib;
let
  cfg = config.garuda.hardware;
in
{
  options.garuda.hardware = {
    enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = ''
        Hardware baseline: CPU microcode updates, redistributable
        firmware, and the graphics stack (including 32-bit support on
        GUI systems).
      '';
    };

    autoDriver = {
      enable = lib.mkEnableOption "hardware auto-detection via nixos-facter" // {
        default = true;
      };
      reportPath = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.path;
        example = "./facter.json";
        description = ''
          Path to the nixos-facter report (written by the installer).
          Takes effect only when autoDriver.enable is set and the
          nixos-facter module is imported. Null disables it.
        '';
      };
    };

    laptop = {
      enable = lib.mkEnableOption "laptop power/thermal tuning";
    };

    nvidia = {
      enable = lib.mkEnableOption "proprietary NVIDIA driver support with the latest drivers";
      amdgpuBusId = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.str;
        example = "PCI:105:0:0";
        description = ''
          PCI bus ID of the AMD iGPU for PRIME offload
          (hardware.nvidia.prime.amdgpuBusId).
        '';
      };
      nvidiaBusId = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.str;
        example = "PCI:1:0:0";
        description = ''
          PCI bus ID of the NVIDIA dGPU for PRIME offload
          (hardware.nvidia.prime.nvidiaBusId).
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.autoDriver.enable && cfg.autoDriver.reportPath != null) {
      hardware.facter.reportPath = lib.mkIf (config.hardware ? facter) cfg.autoDriver.reportPath;
    })
    (lib.mkIf cfg.enable {
      hardware = {
        cpu = {
          amd.updateMicrocode = gDefault true;
          intel.updateMicrocode = gDefault true;
        };
        enableRedistributableFirmware = gDefault true;
        graphics = {
          enable = gDefault config.garuda.system.isGui;
          enable32Bit = gDefault config.garuda.system.isGui;
        };
      };
    })
    (lib.mkIf cfg.laptop.enable {
      services.thermald.enable = gDefault true;
      powerManagement.powertop.enable = gDefault true;
    })
    (lib.mkIf cfg.nvidia.enable {
      hardware = {
        graphics = {
          extraPackages = with pkgs; [
            nvidia-vaapi-driver
          ];
        };
        nvidia = {
          modesetting.enable = gDefault true;
          open = gDefault true;
          package = gDefault (
            config.boot.kernelPackages.nvidiaPackages.mkDriver {
              version = "615.71.09";
              sha256_64bit = "sha256-zc7tIrvrYSSNGm3qvCWWZz46ZQFpjucayNL9wo87cP4=";
              sha256_aarch64 = "sha256-IbekQhE7cFfmnPZaLY9NDYcF7CoNZ+2Qb7sRd4EOgWM=";
              openSha256 = "sha256-3gByMYIwFzRaLdDG+roCEOuKRRJDrljG9AlLnRZTirM=";
              settingsSha256 = "sha256-LK1LU8mDkM/XVRKPBtuOZh9nIP/lGFLAJnmasEX8jhg=";
              persistencedSha256 = "sha256-qPRb+3d88+2RcpUkoBTbjIaImnQ+jX+/6p1vXcJ5geE=";
            }
          );
          prime = {
            offload = {
              enable = gDefault (cfg.nvidia.amdgpuBusId != null && cfg.nvidia.nvidiaBusId != null);
              enableOffloadCmd = gDefault true;
            };
          }
          // lib.optionalAttrs (cfg.nvidia.amdgpuBusId != null) {
            amdgpuBusId = gDefault cfg.nvidia.amdgpuBusId;
          }
          // lib.optionalAttrs (cfg.nvidia.nvidiaBusId != null) {
            nvidiaBusId = gDefault cfg.nvidia.nvidiaBusId;
          };
          powerManagement = {
            enable = gDefault true;
            finegrained = gDefault (cfg.nvidia.amdgpuBusId != null && cfg.nvidia.nvidiaBusId != null);
          };
        };
      };
      services.xserver.videoDrivers = [
        "nvidia"
      ];
    })
  ];
}
