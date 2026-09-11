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
      ];
    };
  }
)
