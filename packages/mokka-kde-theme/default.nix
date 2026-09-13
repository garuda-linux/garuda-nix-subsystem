{
  fetchFromGitLab,
  lib,
  stdenvNoCC,
}:

let
  current = lib.trivial.importJSON ./version.json;
  srcMeta = {
    inherit (current) rev hash;
    group = "garuda-linux";
    owner = "themes-and-settings/settings";
    repo = "garuda-mokka";
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "mokka-kde-theme";
  inherit (current) version;

  src = fetchFromGitLab srcMeta;

  installPhase = ''
    runHook preInstall
    install -d $out/skel
    cp -r etc/skel $out/
    install -d $out/share
    cp -r usr/share/* $out/share/
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

    substituteInPlace etc/skel/.config/autostart/initial-setup.desktop \
      --replace "/etc/skel/.config/autostart/initial-setup.sh" "~/.config/autostart/initial-setup.sh"

    substituteInPlace usr/share/fastfetch/presets/mokka.jsonc \
      --replace "/usr/share/icons/garuda/mokka-fastfetch.png" "/run/current-system/sw/share/icons/garuda/mokka-fastfetch.png"

    substituteInPlace usr/share/plasma/layout-templates/org.garuda.desktop.defaultPanel/contents/layout.js usr/share/plasma/layout-templates/org.garuda.desktop.defaultDock/contents/layout.js \
      --replace "/usr/share" "/run/current-system/sw/share" \
      --replace "applications:garuda-toolbox.desktop," "" \
      --replace ",applications:snapper-tools.desktop" "" \
      --replace ",applications:octopi.desktop" ""

    substituteInPlace usr/share/plasma/look-and-feel/MokkaKitty/contents/layouts/org.kde.plasma.desktop-layout.js \
      --replace "/usr/share" "/run/current-system/sw/share"

    substituteInPlace etc/skel/.config/kscreenlockerrc \
      --replace "wallpapers/garuda-mokka/City-horizon Mocha.jpg" "wallpapers/Mokka-tree/contents/images/3840x2160.jpg"

    substituteInPlace usr/share/plasma/look-and-feel/Mokka/contents/defaults \
      --replace "wallpapers/garuda-mokka/Mokka-tree.jpg" "wallpapers/Mokka-tree/contents/images/3840x2160.jpg"
  '';

  meta = with lib; {
    description = "The default Garuda Mokka theme";
    homepage = "https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-mokka";
    license = licenses.gpl3Only;
    maintainers = [ maintainers.dr460nf1r3 ];
    platforms = platforms.linux;
  };
}
