{ garuda-lib, ... }: 
with garuda-lib;
{
  boot = {
    consoleLogLevel = gDefault 0;
    kernelParams = gExcludableArray "kernelparameters" [ "quiet" ];
    plymouth = {
      enable = gDefault true;
      theme = gDefault "bgrt";
    };
  };
}
