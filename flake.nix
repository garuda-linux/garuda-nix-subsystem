{
  description = "Garuda Linux Nix subsystem flake ❄️";

  nixConfig.extra-substituters = [ "https://nyx.chaotic.cx" ];
  nixConfig.extra-trusted-public-keys = [
    "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
  ];

  inputs = {
    # The Chaotic's Nyx
    chaotic-nyx.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    chaotic-nyx.inputs.home-manager.follows = "home-manager";

    # Devshell to set up a development environment
    devshell.url = "github:numtide/devshell";
    devshell.flake = false;

    # Common used input of our flake inputs
    flake-utils.url = "github:numtide/flake-utils";

    # If you need to, override this to use a different nixpkgs version
    # by default we follow Chaotic Nyx' nyxpkgs-unstable branch
    nixpkgs.follows = "chaotic-nyx/nixpkgs";

    # Have a local index of nixpkgs for fast launching of apps
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # Easy linting of the flake and all kind of other stuff
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS hardware database
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Home configuration management
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Spicetify
    spicetify-nix.url = "github:the-argus/spicetify-nix";
    spicetify-nix.inputs.flake-utils.follows = "flake-utils";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    { devshell
    , flake-parts
    , nixpkgs
    , pre-commit-hooks
    , self
    , ...
    } @ inp:
    let
      inputs = inp;

      internal = import ./internal { inputs = inputs // { inherit nixpkgs; }; inherit lib; };
      lib = import ./lib { inherit inputs nixpkgs internal; };

      perSystem =
        { pkgs
        , system
        , ...
        }: {
          checks.pre-commit-check = pre-commit-hooks.lib.${system}.run {
            hooks = {
              actionlint.enable = true;
              commitizen.enable = true;
              deadnix.enable = true;
              nil.enable = true;
              nixpkgs-fmt.enable = true;
              prettier.enable = true;
              yamllint.enable = true;
              statix.enable = true;
            };
            src = ./.;
          };

          devShells =
            let
              garuda-update = pkgs.callPackage ./devshell/gns-update.nix {
                all-packages = pkgs;
                garuda-lib = lib;
                inherit system self;
              };
              installer = pkgs.callPackage ./devshell/installer.nix {
                all-packages = pkgs;
                garuda-lib = lib;
                inherit system;
              };
              makeDevshell = import "${inp.devshell}/modules" pkgs;
              mkShell = config: (makeDevshell {
                configuration = {
                  inherit config;
                  imports = [ ];
                };
              }).shell;
            in
            rec {
              default = gns-shell;
              gns-install = pkgs.mkShell {
                buildInputs = [ installer garuda-update ];
              };
              gns-update = pkgs.mkShell {
                buildInputs = [ garuda-update ];
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
            };

          formatter = pkgs.nixpkgs-fmt;

          packages.docs = pkgs.runCommand "gns-docs"
            { nativeBuildInputs = with pkgs; [ bash mdbook ]; }
            ''
              bash -c "errors=$(mdbook build -d $out ${./.}/docs |& grep ERROR)
              if [ \"$errors\" ]; then
                exit 1
              fi"
            '';
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.pre-commit-hooks.flakeModule ];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      inherit perSystem;
    };
}
