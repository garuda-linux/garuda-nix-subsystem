{ config
, garuda-lib
, ...
}:
with garuda-lib;
{
  boot = {
    consoleLogLevel = gDefault 0;
    initrd =  {
      systemd.enable = gDefault true;
      systemd.strip = gDefault true;
      verbose = gDefault false;
    };
    kernelParams = gExcludableArray config "kernelparameters" [ "acpi_call" "quiet" ];
    plymouth = {
      enable = gDefault true;
      theme = gDefault "bgrt";
    };
    tmp = {
      # Clean /tmp on boot if not using tmpfs
      cleanOnBoot = gDefault (!config.boot.tmp.useTmpfs);
    };
  };
}
