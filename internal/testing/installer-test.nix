{ pkgs, ... }:
pkgs.testers.runNixOSTest {
  name = "garuda-installer-template";
  nodes.machine = {
    environment.systemPackages = with pkgs; [
      nix
      python3
    ];
  };
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    machine.succeed("cp -r ${../..}/packages/calamares-nixos-extensions/template /tmp/tmpl")
    machine.succeed("cp ${../..}/packages/calamares-nixos-extensions/installer-lib/garuda_template.py /tmp/")
    machine.succeed("cp ${./checks/check_installer_template.py} /tmp/check_installer_template.py")

    out = machine.succeed("python3 /tmp/check_installer_template.py /tmp/tmpl")
    print(out)
  '';
}
