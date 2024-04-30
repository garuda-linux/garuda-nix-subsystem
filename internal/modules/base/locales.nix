{ garuda-lib
, lib
, pkgs
, ...
}:
with lib;
with garuda-lib; {
  config = {
    # Use the Terminus font for the console
    console = {
      earlySetup = true;
      font = "${pkgs.terminus_font}/share/consolefonts/ter-120n.psf.gz";
      packages = with pkgs; [ terminus_font ];
    };
  };
}
