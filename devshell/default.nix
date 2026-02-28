{
  nixpkgs,
  pkgs,
  packages,
  config,
}:

let
  preCommitCompat = pkgs.writeShellScriptBin "pre-commit" ''
    exec ${pkgs.lib.getExe pkgs.prek} "$@"
  '';
in
{
  default = {
    env = [
      {
        name = "NIX_PATH";
        value = "nixpkgs=${nixpkgs}";
      }
    ];
    commands = [
      { package = "mdbook"; }
      { package = "prek"; }
      {
        name = "gns-install";
        category = "garuda tools";
        command = with packages.internal; "${installer}/bin/gns-install";
        help = "Install the Garuda Nix Subsystem";
      }
      {
        name = "gns-update";
        category = "garuda tools";
        command = with packages.internal; "${garuda-update}/bin/gns-update";
        help = "Update the Garuda Nix Subsystem";
      }
    ];
    packages = [
      preCommitCompat
    ];
    devshell = {
      startup = {
        preCommitHooks.text = config.pre-commit.installationScript;
      };
    };
  };

  gns-install = {
    packages = with packages.internal; [
      installer
      garuda-update
    ];
  };

  gns-update = {
    packages = with packages.internal; [
      garuda-update
    ];
  };
}
