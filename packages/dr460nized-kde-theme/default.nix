{
  beautyline-icons,
  fetchFromGitLab,
  fetchurl,
  lib,
  plasma-plugin-blurredwallpaper,
  stdenvNoCC,
  sweet-nova,
}:

let
  current = lib.trivial.importJSON ./version.json;
  srcMeta = {
    inherit (current) rev hash;
    group = "garuda-linux";
    owner = "themes-and-settings/settings";
    repo = "garuda-dr460nized";
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "dr460nized-kde-theme";
  inherit (current) version;

  src = fetchFromGitLab srcMeta;

  maldrakor = fetchurl {
    url = "https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-dr460nized/-/raw/main/usr/share/wallpapers/Maldrakor/contents/3840x1920.jpg";
    hash = "sha256-H7qwdrKKLuYXQbJg+jTxOAZNKMn3iCTsQtyl1kfFNvc=";
  };

  buildInputs = [
    beautyline-icons
    plasma-plugin-blurredwallpaper
    sweet-nova
  ];

  installPhase = ''
    runHook preInstall
    install -d $out/skel
    cp -r etc/skel $out/
    install -d $out/share
    cp -r usr/share/* $out/share/
    install -Dm644 $maldrakor $out/share/wallpapers/Maldrakor/contents/3840x1920.jpg
    runHook postInstall
  '';
  postPatch = ''
    for file in $(find ./* \( -type f \( -name "*.profile" -o -name "*.conf" -o ! -name "*.*" \) \) -o -type l ); do
      if [ -h $file ]; then
        ln -fs $(readlink $file | sed -e 's|/usr/share|/run/current-system/sw/share|g') $file
      else
        substituteInPlace $file --replace "/usr/bin" "/run/current-system/sw/bin" --replace "/usr/share" "/run/current-system/sw/share"
      fi
    done

    substituteInPlace usr/share/plasma/{look-and-feel/Dr460nized/contents/layouts/org.kde.plasma.desktop-layout.js,layout-templates/org.garuda.desktop.defaultDock/contents/layout.js} \
      --replace "applications:garuda-welcome.desktop," "" \
      --replace "applications:snapper-tools.desktop," "" \
      --replace ",applications:octopi.desktop" ""
  '';

  meta = with lib; {
    description = "The default Garuda dr460nized theme";
    homepage = "https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-dr460nized";
    license = licenses.gpl3Only;
    maintainers = [ maintainers.dr460nf1r3 ];
    platforms = platforms.linux;
  };
}
