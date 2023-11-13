{ inputs
, nixpkgs
, self ? inputs.self
, system
, pkgs
, packages
}:

let
  makeDevshell = import "${inputs.devshell}/modules" pkgs;
  mkShell = config:
    (makeDevshell {
      configuration = {
        inherit config;
        imports = [ ];
      };
    }).shell;
in
rec {
  default = gns-shell;
  gns-install = pkgs.mkShell {
    buildInputs = with packages.internal; [ installer garuda-update ];
  };
  gns-update = pkgs.mkShell {
    buildInputs = with packages.internal; [ garuda-update ];
  };
  gns-shell = mkShell {
    devshell.name = "garuda-nix-subsystem";
    commands = [
      { package = "commitizen"; }
      { package = "manix"; }
      { package = "mdbook"; }
      { package = "nix-melt"; }
      { package = "pre-commit"; }
      { package = "yamlfix"; }
      {
        name = "gns-install";
        category = "garuda tools";
        command = "${self.devShells.${system}.gns-install}";
        help = "Install the Garuda Nix Subsystem";
      }
      {
        name = "gns-update";
        category = "garuda tools";
        command = "${self.devShells.${system}.gns-update}";
        help = "Update the Garuda Nix Subsystem";
      }
    ];
    devshell.startup = {
      preCommitHooks.text = self.checks.${system}.pre-commit-check.shellHook;
      gnsEnv.text = ''
        export NIX_PATH=nixpkgs=${nixpkgs}
      '';
    };
  };
}
