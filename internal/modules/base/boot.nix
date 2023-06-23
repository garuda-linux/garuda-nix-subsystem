{ config
, garuda-lib
, ...
}:
with garuda-lib;
{
  boot = {
    consoleLogLevel = gDefault 0;
    initrd = gDefault {
      systemd.enable = true;
      systemd.strip = true;
      verbose = false;
    };
    kernelParams = gExcludableArray "kernelparameters" [ "acpi_call" "quiet" ];
    plymouth = gDefault {
      enable = true;
      theme = "bgrt";
    };
    tmp = {
      # Clean /tmp on boot if not using tmpfs
      cleanOnBoot = gDefault (!config.boot.tmp.useTmpfs);
    };
  };
}
