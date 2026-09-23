{
  glibcLocales,
  stdenv,
  lib,
  garuda-installer-lib,
}:

stdenv.mkDerivation {
  pname = "calamares-nixos-extensions";
  version = "0.3.23";

  src = ./.;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{etc,lib,share}/calamares
    cp -r modules $out/lib/calamares/
    ln -s ${garuda-installer-lib}/share/garuda-installer-lib $out/lib/calamares/installer-lib
    ln -s ${garuda-installer-lib}/share/garuda-installer-lib/template $out/lib/calamares/template
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
