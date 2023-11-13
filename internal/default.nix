{ inputs, lib, overlay, ... }@fromFlake:
{
  modules = import ./modules { inherit inputs lib fromFlake overlay; };
  inherit ((lib.garudaSystem {
    system = "x86_64-linux";
    modules = [ ./testing/vm.nix ];
  }).config.system.build) vm;
  ci = (lib.garudaSystem {
    system = "x86_64-linux";
    modules = [ ./testing/ci.nix ];
  }).config.system.build.vm;
}
