{ inputs, lib, ... }@fromFlake:
{
  modules = import ./modules { inherit inputs lib fromFlake; };
  inherit ((lib.garudaSystem {
    system = "x86_64-linux";
    modules = [ ./testing/vm.nix ];
  }).config.system.build) vm;
}
