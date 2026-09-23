{
  lib,
  all-packages,
  garuda-lib,
  garuda-installer-lib,
  makeWrapper,
  python3,
  system,
  self,
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
  pname = "gns-update";
  inherit version;
  format = "other";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = [ python3.pkgs.questionary ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp gns_update.py $out/bin/gns-update
    chmod +x $out/bin/gns-update
    wrapProgram $out/bin/gns-update \
      --set GNS_INSTALLER_LIB ${garuda-installer-lib}/share/garuda-installer-lib \
      --set GNS_VERSION "${version}" \
      --set GNS_SELF "${toString self}" \
      --prefix PATH : ${
        lib.makeBinPath (
          with all-packages;
          [
            util-linux
            btrfs-progs
            coreutils
            git
            nixos.nixos-install
            nh
            nix
          ]
        )
      }
    runHook postInstall
  '';

  meta = with lib; {
    description = "Update the Garuda Nix Subsystem";
    homepage = "https://gitlab.com/garuda-linux/garuda-nix-subsystem";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "gns-update";
  };
}
