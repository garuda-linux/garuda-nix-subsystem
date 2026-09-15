{
  lib,
  config,
  osConfig,
  pkgs,
  garuda-lib,
  ...
}:
import ../theme/generic-metafiles.nix
  {
    terminalEntries = false;
    startcenterIcon = "libreoffice";
    writerIcon = "libreoffice-writer";
  }
  {
    inherit
      lib
      config
      osConfig
      pkgs
      garuda-lib
      ;
  }
