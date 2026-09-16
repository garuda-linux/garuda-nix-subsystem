{
  inputs,
  nixpkgs,
  internal,
  ...
}@fromFlake:
rec {
  garuda-lib = import ./garuda-lib.nix { inherit inputs nixpkgs fromFlake; };

  garudaSystem =
    args:
    nixpkgs.lib.nixosSystem (
      args
      // {
        extraModules = [ internal.modules.default ] ++ args.extraModules or [ ];
        specialArgs = {
          inherit garuda-lib;
        }
        // args.specialArgs or { };
      }
    );
  nixosSystem = garudaSystem;

  mkISO =
    edition:
    (garudaSystem {
      system = "x86_64-linux";
      modules = [
        ../internal/testing/iso.nix
        {
          garuda.${edition}.enable = true;
          isoImage.edition = edition;
        }
      ];
      specialArgs = {
        flake-inputs = inputs;
      };
    }).config.system.build.isoImage;

  mkVm =
    edition: extraModules:
    (garudaSystem {
      system = "x86_64-linux";
      modules = [
        ../internal/testing/vm-base.nix
        {
          garuda.${edition}.enable = true;
        }
      ]
      ++ extraModules;
    }).config.system.build.vm;

  mkCiVm =
    edition: extraModules:
    mkVm edition (
      [
        {
          garuda.subsystem.enable = true;
          garuda.managed.config = ../internal/testing/garuda-managed.json;
        }
      ]
      ++ extraModules
    );

  mkBootTest =
    {
      pkgs,
      garuda-modules,
      edition,
    }:
    import ../internal/testing/boot-test.nix {
      inherit
        pkgs
        garuda-modules
        garuda-lib
        edition
        ;
    };
}
