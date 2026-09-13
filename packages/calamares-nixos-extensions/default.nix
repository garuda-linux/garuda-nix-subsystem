{
  glibcLocales,
  stdenv,
  lib,
}:

stdenv.mkDerivation {
  pname = "calamares-nixos-extensions";
  version = "0.3.23";

  src = ./.;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{etc,lib,share}/calamares
    cp -r modules $out/lib/calamares/
    cp -r installer-lib $out/lib/calamares/
    cp -r template $out/lib/calamares/
    cp -r config/* $out/etc/calamares/
    cp -r branding $out/share/calamares/

    substituteInPlace $out/etc/calamares/settings.conf --replace-fail @out@ $out
    substituteInPlace $out/etc/calamares/modules/locale.conf --replace-fail @glibcLocales@ ${glibcLocales}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Calamares modules for Garuda Nix";
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
