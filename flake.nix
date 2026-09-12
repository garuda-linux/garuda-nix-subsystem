{
  description = "Garuda Linux NixOS flake ❄️";

  nixConfig.extra-substituters = [
    "https://nyx-cache.chaotic.cx/"
  ];
  nixConfig.extra-trusted-public-keys = [
    "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
  ];

  inputs = {
    # OS internals
    nixpkgs.follows = "chaotic-nyx/nixpkgs";

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic-nyx = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ksv-cachyos-settings-nixos = {
      url = "github:vivekanandan-ks/ksv-cachyos-settings-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    # Dev tools
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      internal = import ./internal {
        inherit lib;
        overlay = import ./packages/overlay.nix {
          inherit inputs lib;
        };
        inputs = inputs // {
          inherit nixpkgs;
        };
      };

      lib = import ./lib { inherit inputs nixpkgs internal; };

      mkPackages =
        system:
        import ./packages {
          inherit system inputs lib;
          pkgs = nixpkgs.legacyPackages.${system};
        };

      mkPreCommitCheck =
        pkgs:
        inputs.git-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
          src = ./.;
          package = pkgs.prek;
          hooks = {
            commitizen.enable = true;
            treefmt = {
              enable = true;
              package = self.formatter.${pkgs.stdenv.hostPlatform.system};
            };
          };
        };

      mkTreefmtEval =
        pkgs:
        import ./devshells/formatter.nix {
          inherit pkgs;
          inherit (inputs) treefmt-nix;
        };
    in
    {
      inherit lib internal;

      packages = forAllSystems (pkgs: (mkPackages pkgs.stdenv.hostPlatform.system).external);

      checks = forAllSystems (pkgs: {
        pre-commit = mkPreCommitCheck pkgs;
      });

      devShells = import ./devshells {
        inherit self forAllSystems mkPackages;
        inherit (self) checks;
      };

      formatter = forAllSystems mkTreefmtEval;
    };
}
