{
  lib,
  makeWrapper,
  python3,
  garuda-installer-lib,
  parted,
  dosfstools,
  e2fsprogs,
  btrfs-progs,
  cryptsetup,
  mkpasswd,
}:

python3.pkgs.buildPythonApplication {
  pname = "install-garuda-nix";
  version = "0.1.0";
  format = "other";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = [ python3.pkgs.questionary ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp install-garuda-nix.py $out/bin/install-garuda-nix
    chmod +x $out/bin/install-garuda-nix
    wrapProgram $out/bin/install-garuda-nix \
      --set GNS_INSTALLER_LIB ${garuda-installer-lib}/share/garuda-installer-lib \
      --set GNS_TEMPLATE_DIR ${garuda-installer-lib}/share/garuda-installer-lib/template \
      --prefix PATH : ${
        lib.makeBinPath [
          parted
          dosfstools
          e2fsprogs
          btrfs-progs
          cryptsetup
          mkpasswd
        ]
      }
    runHook postInstall
  '';

  meta = with lib; {
    description = "Generate a Garuda NixOS system config from the CLI";
    homepage = "https://gitlab.com/garuda-linux/garuda-nix-subsystem";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "install-garuda-nix";
  };
}
