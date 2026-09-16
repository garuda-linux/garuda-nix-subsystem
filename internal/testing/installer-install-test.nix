{ pkgs, inputs, ... }:
let
  installerPkg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.install-garuda-nix;
in
pkgs.testers.runNixOSTest {
  name = "garuda-installer-install";
  nodes.machine = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      dosfstools
      e2fsprogs
      git
      installerPkg
      nix
      nixos-facter
      nixos-install-tools
      parted
      python3
    ];
    nix.settings = {
      accept-flake-config = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = pkgs.lib.mkForce [
        "https://cache.nixos.org"
        "https://nyx-cache.chaotic.cx/"
      ];
      trusted-public-keys = pkgs.lib.mkForce [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
      ];
    };
    virtualisation = {
      memorySize = 8192;
      cores = 4;
      diskSize = 4096;
      emptyDiskImages = [ 20480 ];
    };
  };
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    # 1. No manual partitioning: the CLI wipes /dev/vdb itself with the
    # default (btrfs) schema, testing garuda_partition.py end to end.
    # 2. Run the real installer CLI (mokka + gaming) against the
    # mounted target. GNS_FLAKE_REF points at the repo under test so
    # the offline guest resolves flake inputs without network.
    machine.succeed("cp -r ${../..} /tmp/repo && chmod -R u+w /tmp/repo")

    # 3. Real install via the CLI's --install path (no bootloader:
    # EFI vars are unreliable in the test VM).
    # execute() instead of succeed(): returns status without throwing, so the
    # diagnostics below always run instead of the log dying with the step.
    status, out = machine.execute(
      "GNS_FLAKE_REF=path:/tmp/repo install-garuda-nix --flavor mokka --feature gaming "
      "--root /mnt --disk /dev/vdb --yes --bootloader systemd-boot --install --no-bootloader "
      "> /tmp/install.log 2>&1; echo INSTALL_RC=$?",
      timeout=3600,
    )
    # succeed() stdout is swallowed by the driver log on success, but the
    # return value is still captured: embed everything in the assert message,
    # which survives via the traceback.
    install_log = machine.succeed("tail -100 /tmp/install.log; echo ---ERRORS---; grep -i -E 'error|failed|substituter|connection|timeout' /tmp/install.log | tail -30")
    install_sizes = machine.succeed("ls -l /tmp/install.log; wc -l /tmp/install.log")
    assert status == 0, f"nixos-install failed: out={out} sizes={install_sizes} tail={install_log}"

    # 4. Assert install artifacts (nixos-install sets the system profile but
    # never activates: /run/current-system only appears at first boot).
    # Profile links are absolute (/nix/store/...): resolve them under /mnt.
    r, o = machine.execute(
      "t=$(readlink /mnt/nix/var/nix/profiles/system-1-link); "
      'echo "TOPLEVEL=$t"; '
      'test -x "/mnt$t/bin/switch-to-configuration" && echo STC_OK; '
      'test -e "/mnt$t/init" && echo INIT_OK'
    )
    assert r == 0 and "STC_OK" in o and "INIT_OK" in o, f"bad system profile: rc={r} out={o!r}"
    machine.succeed("test -e /mnt/etc/nixos/flake.nix")
    machine.succeed("grep -q 'garuda-nix' /mnt/etc/nixos/flake.nix")
    machine.succeed("test -e /mnt/etc/nixos/nixos/hardware-configuration.nix")
    machine.succeed("test -e /mnt/etc/nixos/nixos/facter.json")
    machine.succeed("grep -q 'garuda.mokka.enable' /mnt/etc/nixos/nixos/configuration.nix")
    print("install OK")
  '';
}
