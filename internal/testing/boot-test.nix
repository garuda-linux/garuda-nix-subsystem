{
  pkgs,
  garuda-lib,
  garuda-modules,
}:
pkgs.testers.runNixOSTest {
  name = "garuda-boot";
  node.pkgsReadOnly = false;
  defaults.imports = [
    ./vm-mokka-bare.nix
    garuda-modules
  ];
  node.specialArgs = { inherit garuda-lib; };
  nodes.machine.virtualisation.memorySize = 4096;
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("id garuda")
    machine.succeed("test -e /run/current-system")
  '';
}
