{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
import ../theme/generic-metafiles.nix
  {
    terminalEntries = true;
    startcenterIcon = "org.libreoffice.LibreOffice-startcenter";
    writerIcon = "org.libreoffice.LibreOffice-writer";
  }
  {
    inherit
      lib
      config
      osConfig
      pkgs
      ;
  }
