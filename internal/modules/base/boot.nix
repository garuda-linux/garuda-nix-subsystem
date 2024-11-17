{ config
, garuda-lib
, ...
}:
with garuda-lib;
{
  options.garuda.excludes = gCreateExclusionOption "kernelparameters";

  config.boot = {
    consoleLogLevel = gDefault 0;
    # Make use of the systemd initrd
    initrd = {
      systemd.enable = gDefault true;
      systemd.strip = gDefault true;
      verbose = gDefault false;
    };
    # Make it quiet by default
    kernelParams = gExcludableArray config "kernelparameters" [ "acpi_call" "quiet" ];
    # Enables Plymouth with the bgrt theme (UEFI splash screen)
    plymouth = {
      enable = gDefault config.garuda.system.isGui;
      theme = gDefault "bgrt";
    };
    tmp = {
      # Clean /tmp on boot if not using tmpfs
      cleanOnBoot = gDefault (!config.boot.tmp.useTmpfs);
    };
  };
}
