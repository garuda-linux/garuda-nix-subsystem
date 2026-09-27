{
  lib,
  writeShellApplication,
  inxi,
  efibootmgr,
  gawk,
  coreutils,
  gnugrep,
  systemd,
  kmod,
  nix,
  findutils,
  util-linux,
}:

writeShellApplication {
  name = "garuda-inxi";

  runtimeInputs = [
    inxi
    efibootmgr
    gawk
    coreutils
    gnugrep
    systemd
    kmod
    nix
    findutils
    util-linux
  ];

  text = builtins.readFile ./garuda-inxi.sh;

  meta = with lib; {
    description = "Wrapper around inxi with Garuda Nix-specific information (port of garuda-common-settings garuda-inxi)";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "garuda-inxi";
  };
}
