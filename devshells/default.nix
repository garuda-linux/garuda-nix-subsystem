{
  self,
  forAllSystems,
  checks,
  mkPackages,
}:
forAllSystems (
  pkgs:
  let
    system = pkgs.stdenv.hostPlatform.system;
    inherit (checks.${system}.pre-commit)
      shellHook
      enabledPackages
      ;

    packages = mkPackages system;

    preCommitCompat = pkgs.writeShellScriptBin "pre-commit" ''
      exec ${pkgs.lib.getExe pkgs.prek} "$@"
    '';

    gns-install = pkgs.writeShellScriptBin "gns-install" ''
      exec ${packages.internal.installer}/bin/gns-install "$@"
    '';

    gns-update = pkgs.writeShellScriptBin "gns-update" ''
      exec ${packages.internal."garuda-update"}/bin/gns-update "$@"
    '';

    buildiso = pkgs.writeShellScriptBin "buildiso" ''
      set -euo pipefail
      flavour=''${1:?usage: buildiso [dr460nized|mokka|all] [--run]}
      run_iso=false
      if [[ ''${2:-} == --run ]]; then run_iso=true; fi

      build() {
        local out
        out=$(nix build ".#internal.iso-$1" --no-link --print-out-paths)
        ${pkgs.coreutils}/bin/cp -f "$out/iso/"*.iso .
      }

      case "$flavour" in
        all) build dr460nized; build mokka ;;
        dr460nized|mokka) build "$flavour" ;;
        *) echo "usage: buildiso [dr460nized|mokka|all] [--run]" >&2; exit 1 ;;
      esac

      if $run_iso; then
        iso=$(ls -t ./*.iso | ${pkgs.coreutils}/bin/head -n1)
        ovmf=$(nix build "nixpkgs#OVMF.fd" --no-link --print-out-paths)
        disk=nixos-test.qcow2

        if [[ ! -f $disk ]]; then
          nix shell "nixpkgs#qemu_kvm" -c qemu-img create -f qcow2 "$disk" 30G
        fi

        exec nix shell "nixpkgs#qemu_kvm" -c qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cpu host \
          -bios "$ovmf/FV/OVMF.fd" -boot order=d -cdrom "$iso" \
          -drive file="$disk",if=virtio,format=qcow2 \
          -vga virtio -display gtk -device virtio-rng-pci
      fi
    '';

    runvm = pkgs.writeShellScriptBin "runvm" ''
      set -euo pipefail
      out=$(nix build ".#internal.vm" --no-link --print-out-paths)
      exec "$out/bin/run-nixos-vm"
    '';

    gendocs = pkgs.writeShellScriptBin "gendocs" ''
      set -euo pipefail
      out=$(nix build ".#internal.options-doc" --no-link --print-out-paths)
      ${pkgs.coreutils}/bin/cp -f "$out" docs/src/nixos-module/options.md
      echo "docs/src/nixos-module/options.md regenerated"
    '';

    docs = pkgs.writeShellScriptBin "docs" ''
      set -euo pipefail
      gendocs
      exec ${pkgs.mdbook}/bin/mdbook "$@" -d docs/book docs
    '';
  in
  {
    default = pkgs.mkShell {
      inherit shellHook;

      buildInputs = [
        self.formatter.${system}
      ];

      packages = enabledPackages ++ [
        pkgs.mdbook
        pkgs.prek
        preCommitCompat
        gns-install
        gns-update
        buildiso
        runvm
        gendocs
        docs
      ];
    };
  }
)
