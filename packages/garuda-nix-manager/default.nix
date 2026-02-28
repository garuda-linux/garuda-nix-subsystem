{
  stdenv,
  wrapQtAppsHook,
  qtbase,
  cmake,
  jq,
  lib,
  coreutils,
  makeDesktopItem,
  copyDesktopItems,
  launch-terminal,
}:
stdenv.mkDerivation (final: {
  pname = "garuda-nix-manager";
  version = "1.0.0";
  src = builtins.fetchGit {
    url = "https://gitlab.com/garuda-linux/applications/garuda-nix-manager.git";
    ref = "main";
    rev = "c4073ec78c98b409fac3acaddde44e8a6a3f2ea6";
  };

  buildInputs = [ qtbase ];
  nativeBuildInputs = [
    wrapQtAppsHook
    cmake
    copyDesktopItems
  ];

  qtWrapperArgs = [
    "--suffix PATH : ${lib.makeBinPath [ launch-terminal ]}"
  ];

  postInstall = ''
    install -Dm0755 "$src/garuda-nix-manager-pkexec" "$out/lib/garuda-nix-manager/garuda-nix-manager-pkexec"
    install -Dm0644 "$src/org.garuda.garuda-nix-manager.pkexec.policy" "$out/share/polkit-1/actions/org.garuda.garuda-nix-manager.pkexec.policy"

    copyDesktopItems
  '';

  desktopItems = [
    (makeDesktopItem rec {
      name = "Garuda Nix Manager";
      exec = final.pname;
      icon = final.pname;
      desktopName = name;
      genericName = name;
      categories = [
        "System"
        "X-Garuda-Setup"
      ];
    })
  ];

  postFixup = ''
    wrapProgram "$out/lib/garuda-nix-manager/garuda-nix-manager-pkexec" \
      --prefix PATH : ${
        lib.makeBinPath [
          jq
          coreutils
        ]
      }
  '';
})
