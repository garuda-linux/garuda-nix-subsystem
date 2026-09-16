{ pkgs, inputs, ... }:
let
  # The catppuccin combo evaluates lib.importTOML on this theme package
  # inside the guest, but the test VM has no network to realise it.
  # Referencing it here guarantees it is built on the host (network is
  # fine there); the test script (which runs on the host) dumps it and
  # imports it into the guest store before evaluating.
  starshipPkg = inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.starship;
  palettePkg = inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.palette;
in
pkgs.testers.runNixOSTest {
  name = "garuda-installer-eval";
  nodes.machine = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.python3
      pkgs.nix
      pkgs.git
    ];
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nix.settings.accept-flake-config = true;
    virtualisation.memorySize = 4096;
    virtualisation.diskSize = 8192;
  };
  testScript = ''
    import subprocess
    import tempfile

    start_all()
    machine.wait_for_unit("multi-user.target")

    nar = tempfile.NamedTemporaryFile(suffix=".nar", delete=False).name
    paths = subprocess.run(["${pkgs.nix}/bin/nix-store", "-qR", "${starshipPkg}", "${palettePkg}"],
                           capture_output=True, text=True, check=True).stdout.split()
    with open(nar, "wb") as f:
        subprocess.run(["${pkgs.nix}/bin/nix-store", "--export", *paths],
                       stdout=f, check=True)
    machine.copy_from_host(nar, "/tmp/starship-closure.nar")
    machine.succeed("nix-store --import < /tmp/starship-closure.nar")

    machine.succeed("cp -r ${../..} /tmp/repo && chmod -R u+w /tmp/repo")
    machine.succeed("cp -r ${../..}/packages/calamares-nixos-extensions/template /tmp/tmpl")
    machine.succeed("cp ${../..}/packages/calamares-nixos-extensions/installer-lib/garuda_template.py /tmp/")
    machine.succeed("cp ${./checks/check_eval_matrix.py} /tmp/check_eval_matrix.py")
    machine.succeed("cp ${./checks/check_impermanence.py} /tmp/check_impermanence.py")

    out = machine.succeed("python3 /tmp/check_eval_matrix.py /tmp/tmpl /tmp/repo")
    print(out)
    out = machine.succeed("python3 /tmp/check_impermanence.py /tmp/repo")
    print(out)
  '';
}
