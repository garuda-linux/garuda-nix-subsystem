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
      exec ${packages.internal.garuda-update-runner}/bin/garuda-update-runner "$@"
    '';

    buildiso = pkgs.writeShellScriptBin "buildiso" ''
      set -euo pipefail
      edition=''${1:?usage: buildiso [dr460nized|mokka|catppuccin|all] [--run]}
      run_iso=false
      if [[ ''${2:-} == --run ]]; then run_iso=true; fi

      build() {
        local out
        out=$(nix build ".#internal.iso-$1" --no-link --print-out-paths)
        ${pkgs.coreutils}/bin/cp -f "$out/iso/"*.iso .
      }

      case "$edition" in
        all) build dr460nized; build mokka; build catppuccin ;;
        dr460nized|mokka|catppuccin) build "$edition" ;;
        *) echo "usage: buildiso [dr460nized|mokka|catppuccin|all] [--run]" >&2; exit 1 ;;
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

    limatest = pkgs.writeShellApplication {
      name = "limatest";
      runtimeInputs = with pkgs; [
        coreutils
        git
        gnugrep
        gnused
        lima
      ];
      text = builtins.readFile ../internal/testing/lima/limatest.sh;
    };

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

    release = import ./release.nix { inherit pkgs; };
    ci-shell = import ./ci.nix { inherit pkgs; };

    tools = [
      buildiso
      docs
      gendocs
      gns-install
      gns-update
      limatest
      runvm
    ];

    deps = [
      "limactl"
      "mdbook"
      "treefmt"
    ];
  in
  {
    default = pkgs.mkShell {
      shellHook = ''
        ${shellHook}

        if [[ -z ''${CI:-} ]]; then
          printf '\033[1;35mGaruda Nix devshell\033[0m ❄️\n'
          printf '  \033[2mtools:\033[0m %s\n' "${pkgs.lib.concatMapStringsSep " " pkgs.lib.getName tools}"
          printf '  \033[2mdeps: \033[0m %s\n' "${pkgs.lib.concatStringsSep " " deps}"
        fi
      '';

      buildInputs = [
        self.formatter.${system}
      ];

      packages =
        enabledPackages
        ++ tools
        ++ [
          pkgs.lima
          pkgs.mdbook
        ];
    };

    release = release.shell;
    ci = ci-shell.shell;

    gns-install = pkgs.mkShell {
      packages = [
        gns-install
        gns-update
      ];
    };

    gns-update = pkgs.mkShell {
      packages = [ gns-update ];
    };
  }
)
