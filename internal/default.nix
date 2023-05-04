{ inputs, lib, ... }@fromFlake:
rec {
  modules = import ./modules { inherit inputs; };
  inherit ((lib.garudaSystem {
    system = "x86_64-linux";
    modules = [ ./testing/vm.nix ];
  }).config.system.build) vm;
}
