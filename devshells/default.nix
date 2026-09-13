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

    gns-install = pkgs.writeShellScriptBin "gns-install" ''
      exec ${packages.internal.installer}/bin/gns-install "$@"
    '';

    gns-update = pkgs.writeShellScriptBin "gns-update" ''
      exec ${packages.internal."garuda-update"}/bin/gns-update "$@"
    '';

    install-garuda-nix = pkgs.writeShellScriptBin "install-garuda-nix" ''
      exec ${packages.internal.install-garuda-nix}/bin/install-garuda-nix "$@"
    '';

    buildiso = pkgs.writeShellScriptBin "buildiso" ''
      set -euo pipefail
      edition=''${1:?usage: buildiso [dr460nized|mokka|all] [--run]}
      run_iso=false
      if [[ ''${2:-} == --run ]]; then run_iso=true; fi

      build() {
        local out
        out=$(nix build ".#internal.iso-$1" --no-link --print-out-paths)
        ${pkgs.coreutils}/bin/cp -f "$out/iso/"*.iso .
      }

      case "$edition" in
        all) build dr460nized; build mokka ;;
        dr460nized|mokka) build "$edition" ;;
        *) echo "usage: buildiso [dr460nized|mokka|all] [--run]" >&2; exit 1 ;;
      esac

      if $run_iso; then
        iso=$(ls -t ./*.iso | ${pkgs.coreutils}/bin/head -n1)
        ovmf=$(nix build "nixpkgs#OVMF.fd" --no-link --print-out-paths)
        disk=nixos-test.qcow2

        if [[ ! -f $disk ]]; then
          nix shell "nixpkgs#qemu_kvm" -c qemu-img create -f qcow2 "$disk" 30G
        fi

        exec nix shell "nixpkgs#qemu_kvm" -c qemu-system-x86_64 -enable-kvm -m 8192 -smp 8 -cpu host \
          -machine q35,accel=kvm -bios "$ovmf/FV/OVMF.fd" -boot order=d -cdrom "$iso" \
          -drive file="$disk",format=qcow2,if=none,id=drive0 -device virtio-scsi-pci,id=scsi -device scsi-hd,drive=drive0 \
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
        buildiso
        docs
        gendocs
        gns-install
        gns-update
        install-garuda-nix
        pkgs.mdbook
        pkgs.prek
        runvm
      ];
    };
  }
)
