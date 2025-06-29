{ inputs, lib, overlay, ... }@fromFlake:
{
  modules = import ./modules { inherit inputs lib fromFlake overlay; };
  inherit ((lib.garudaSystem {
    system = "x86_64-linux";
    modules = [ ./testing/vm.nix ];
  }).config.system.build) vm;

  ci-bare = (lib.garudaSystem {
    system = "x86_64-linux";
    modules = [ ./testing/ci-bare.nix ];
  }).config.system.build.vm;
  ci-full = (lib.garudaSystem {
    system = "x86_64-linux";
    modules = [ ./testing/ci-full.nix ];
  }).config.system.build.vm;
}
