{
  lib,
  all-packages,
  garuda-lib,
  garuda-installer-lib,
  makeWrapper,
  python3,
  system,
}:
let
  nixos =
    (garuda-lib.garudaSystem {
      inherit system;
      modules = [ { } ];
    }).config.system.build;
  version = toString garuda-lib.garuda-lib.version;
in
python3.pkgs.buildPythonApplication {
  pname = "gns-install";
  inherit version;
  format = "other";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = [ python3.pkgs.questionary ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp installer.py $out/bin/gns-install
    chmod +x $out/bin/gns-install
    wrapProgram $out/bin/gns-install \
      --set GNS_INSTALLER_LIB ${garuda-installer-lib}/share/garuda-installer-lib \
      --set GNS_VERSION "${version}" \
      --prefix PATH : ${
        lib.makeBinPath (
          with all-packages;
          [
            util-linux
            btrfs-progs
            coreutils
            git
            nixos.nixos-generate-config
            nix
          ]
        )
      }
    runHook postInstall
  '';

  meta = with lib; {
    description = "Install the Garuda Nix Subsystem onto the host BTRFS";
    homepage = "https://gitlab.com/garuda-linux/garuda-nix-subsystem";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "gns-install";
  };
}
