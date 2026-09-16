{
  pkgs,
  garuda-lib,
  garuda-modules,
  edition,
}:
pkgs.testers.runNixOSTest {
  name = "garuda-boot-${edition}";
  node.pkgsReadOnly = false;
  defaults.imports = [
    ./vm-base.nix
    { garuda.${edition}.enable = true; }
    garuda-modules
  ];
  node.specialArgs = { inherit garuda-lib; };
  nodes.machine.virtualisation.memorySize = 4096;
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("graphical.target")
    machine.succeed("systemctl is-active display-manager")
    machine.succeed("id garuda")
  '';
}
