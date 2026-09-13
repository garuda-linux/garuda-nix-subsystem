{
  inputs,
  lib,
  overlay,
  ...
}@fromFlake:
{
  modules = import ./modules {
    inherit
      inputs
      lib
      fromFlake
      overlay
      ;
  };
  inherit
    ((lib.garudaSystem {
      system = "x86_64-linux";
      modules = [ ./testing/vm-dr460nized-bare.nix ];
    }).config.system.build
    )
    vm
    ;

  ci-bare =
    (lib.garudaSystem {
      system = "x86_64-linux";
      modules = [ ./testing/ci-bare.nix ];
    }).config.system.build.vm;
  ci-full =
    (lib.garudaSystem {
      system = "x86_64-linux";
      modules = [ ./testing/ci-full.nix ];
    }).config.system.build.vm;

  iso-dr460nized =
    (lib.garudaSystem {
      system = "x86_64-linux";
      modules = [ ./testing/iso-dr460nized.nix ];
      specialArgs = {
        flake-inputs = inputs;
      };
    }).config.system.build.isoImage;
  iso-mokka =
    (lib.garudaSystem {
      system = "x86_64-linux";
      modules = [ ./testing/iso-mokka.nix ];
      specialArgs = {
        flake-inputs = inputs;
      };
    }).config.system.build.isoImage;
}
