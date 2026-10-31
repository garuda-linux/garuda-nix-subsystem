{
  lib,
  all-packages,
  garuda-lib,
  garuda-installer-lib,
  gns-update,
  makeWrapper,
  python3,
}:
let
  version = toString garuda-lib.garuda-lib.version;

  python = python3.withPackages (ps: [
    ps.tree-sitter
    ps.tree-sitter-grammars.tree-sitter-nix
  ]);
  tools = with all-packages; [
    btrfs-progs
    coreutils
    git
    nh
    nix
    util-linux
  ];
in
{
  garuda-update-runner = python3.pkgs.buildPythonApplication {
    pname = "garuda-update";
    inherit version;
    format = "other";

    src = ./.;

    nativeBuildInputs = [ makeWrapper ];

    doCheck = true;
    checkPhase = ''
      runHook preCheck
      ${python}/bin/python3 -m unittest discover -s . -p 'test_*.py'
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/share/garuda-update
      cp runner.py fixes.py nixedit.py $out/share/garuda-update/
      makeWrapper ${python}/bin/python3 $out/bin/garuda-update-runner \
        --add-flags $out/share/garuda-update/runner.py \
        --set GNS_INSTALLER_LIB ${garuda-installer-lib}/share/garuda-installer-lib \
        --set GNS_UPDATE_BIN ${gns-update}/bin/gns-update \
        --prefix PATH : ${lib.makeBinPath tools}
      runHook postInstall
    '';

    meta = with lib; {
      description = "Update Garuda Nix and apply common fixes before the update";
      homepage = "https://gitlab.com/garuda-linux/garuda-nix";
      license = licenses.gpl3Only;
      platforms = platforms.linux;
      mainProgram = "garuda-update-runner";
    };
  };

  garuda-update-launcher = all-packages.writeShellApplication {
    name = "garuda-update";
    runtimeInputs = tools ++ [ python ];
    text = builtins.readFile ./launcher.sh;
  };
}
