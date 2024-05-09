{ config
, garuda-lib
, lib
, pkgs
, ...
}:
with lib;
with garuda-lib; {
  config = {
    # Use the Terminus font for the console
    console = {
      earlySetup = config.garuda.system.isGui;
      font = lib.mkIf config.garuda.system.isGui "${pkgs.terminus_font}/share/consolefonts/ter-120n.psf.gz";
      packages = lib.mkIf config.garuda.system.isGui (with pkgs; [ terminus_font ]);
    };
  };
}
