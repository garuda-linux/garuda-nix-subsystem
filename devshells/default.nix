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
      flavour=''${1:?usage: buildiso [dr460nized|mokka|all]}
      build() {
        local out
        out=$(nix build ".#internal.iso-$1" --no-link --print-out-paths)
        ${pkgs.coreutils}/bin/cp "$out/iso/"*.iso .
      }
      case "$flavour" in
        all) build dr460nized; build mokka ;;
        dr460nized|mokka) build "$flavour" ;;
        *) echo "usage: build-iso [dr460nized|mokka|all]" >&2; exit 1 ;;
      esac
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
      ];
    };
  }
)
