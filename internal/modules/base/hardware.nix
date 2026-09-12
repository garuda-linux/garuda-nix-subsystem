{
  config,
  garuda-lib,
  lib,
  ...
}:
with garuda-lib;
let
  cfg = config.garuda.hardware;
in
{
  options = {
    garuda.hardware.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = ''
        If set to true, reasonable defaults for hardware will be set.
      '';
    };
    garuda.hardware.nvidia = {
      enable = lib.mkEnableOption "proprietary NVIDIA driver";
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
    (lib.mkIf cfg.nvidia.enable {
      hardware.nvidia = {
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
          amdgpuBusId = gDefault cfg.nvidia.amdgpuBusId;
          nvidiaBusId = gDefault cfg.nvidia.nvidiaBusId;
          offload = {
            enable = gDefault true;
            enableOffloadCmd = gDefault true;
          };
        };
        powerManagement = {
          finegrained = gDefault true;
        };
      };
      services.xserver.videoDrivers = [
        "nvidia"
      ];
    })
  ];
}
