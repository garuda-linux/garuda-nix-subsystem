{ config
, garuda-lib
, lib
, pkgs
, ...
}:
with lib;
with garuda-lib;
{
  config = {
    # Console font
    console.font = gDefault "${pkgs.terminus_font}/share/consolefonts/ter-120n.psf.gz";
  };
}

