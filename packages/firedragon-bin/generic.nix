{
  lib,
  stdenv,
  fetchurl,
  wrapGAppsHook3,
  autoPatchelfHook,
  alsa-lib,
  curl,
  dbus-glib,
  gtk3,
  libXtst,
  libva,
  pciutils,
  pipewire,
  adwaita-icon-theme,
  patchelfUnstable,
  # have to use patchelfUnstable to support --no-clobber-old-sections
  shortName,
  description,
  versionFile,
}:

let
  inherit (lib.importJSON versionFile) version sources;

  binaryName = "firedragon";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "${shortName}-unwrapped";
  inherit version;

  src = fetchurl {
    inherit (sources.${stdenv.hostPlatform.system}) url sha256;
  };

  nativeBuildInputs = [
    wrapGAppsHook3
    autoPatchelfHook
    patchelfUnstable
  ];

  buildInputs = [
    gtk3
    adwaita-icon-theme
    alsa-lib
    dbus-glib
    libXtst
  ];

  runtimeDependencies = [
    curl
    pciutils
    libva.out
  ];

  appendRunpaths = [
    "${pipewire}/lib"
  ];

  # Firefox uses "relrhack" to manually process relocations from a fixed offset
  patchelfFlags = [ "--no-clobber-old-sections" ];

  installPhase = ''
    runHook preInstall

    # it's disabled, so remove these unused files
    rm -v updater icons/updater.png updater.ini update-settings.ini

    mkdir -p "$prefix/lib" "$prefix/bin"
    cp -r . "$prefix/lib/${shortName}-${finalAttrs.version}"
    ln -s "$prefix/lib/${shortName}-${finalAttrs.version}/firedragon" "$out/bin/${binaryName}"

    runHook postInstall
  '';

  passthru = {
    inherit binaryName gtk3;
    applicationName = "FireDragon";
    libName = "${shortName}-${finalAttrs.version}";
    ffmpegSupport = true;
    gssSupport = true;
  };

  meta = {
    changelog = "https://gitlab.com/garuda-linux/firedragon/firedragon13/-/blob/main/CHANGELOG.md";
    inherit description;
    homepage = "https://firedragon.garudalinux.org/";
    license = with lib.licenses; [
      mpl20
      mit
    ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    hydraPlatforms = [ ];
    maintainers = with lib.maintainers; [
      dr460nf1r3
    ];
    mainProgram = "firedragon";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
