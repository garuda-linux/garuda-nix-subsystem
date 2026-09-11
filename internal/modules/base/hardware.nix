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
    garuda.hardware.nvidia = lib.mkOption {
      default = false;
      type = lib.types.bool;
      example = true;
      description = ''
        Enable the proprietary NVIDIA driver (also bind the GPU into the
        Garuda container via garuda.garuda-chroot.nvidia).
      '';
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
    (lib.mkIf cfg.nvidia {
      hardware.nvidia = {
        modesetting.enable = gDefault true;
        open = gDefault true;
        package = gDefault config.boot.kernelPackages.nvidiaPackages.latest;
      };
      services.xserver.videoDrivers = [
        "nvidia"
      ];
    })
  ];
}
