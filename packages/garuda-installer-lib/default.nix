{
  stdenv,
  lib,
}:

stdenv.mkDerivation {
  pname = "garuda-installer-lib";
  version = "0.3.23";

  src = ./.;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/garuda-installer-lib
    cp *.py $out/share/garuda-installer-lib/
    cp -r template $out/share/garuda-installer-lib/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Shared Python installer lib and template for Garuda Nix";
    homepage = "https://gitlab.com/garuda-linux/garuda-nix-subsystem";
    license = with licenses; [
      gpl3
      mit
      cc-by-40
      cc-by-sa-40
    ];
    platforms = platforms.linux;
  };
}
