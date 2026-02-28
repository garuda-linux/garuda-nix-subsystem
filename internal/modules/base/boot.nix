{
  config,
  garuda-lib,
  ...
}:
with garuda-lib;
{
  options.garuda.excludes = gCreateExclusionOption "kernelparameters";

  config.boot = {
    consoleLogLevel = gDefault 0;
    # Make use of the systemd initrd
    initrd = {
      systemd.enable = gDefault true;
      verbose = gDefault false;
    };
    # Make it quiet by default
    kernelParams = gExcludableArray config "kernelparameters" [
      "acpi_call"
      "quiet"
    ];
    tmp = {
      # Clean /tmp on boot if not using tmpfs
      cleanOnBoot = gDefault (!config.boot.tmp.useTmpfs);
    };
  };
}
