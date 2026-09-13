{ stdenv, lib }:

stdenv.mkDerivation {
  pname = "calamares-nixos-extensions";
  version = "0.3.23";

  src = ./.;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{lib,share}/calamares
    cp -r modules $out/lib/calamares/
    cp -r config/* $out/share/calamares/
    cp -r branding $out/share/calamares/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Calamares modules Garuda Nix";
    homepage = "https://gitlab.com/garuda-linux/garuda-nix-subsystem";
    license = with licenses; [
      gpl3Plus
      bsd2
      cc-by-40
      cc-by-sa-40
      cc0
    ];
    platforms = platforms.linux;
  };
}
