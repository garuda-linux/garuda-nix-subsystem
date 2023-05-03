{ inputs, ... }@fromFlake:
rec {
  modules = import ./modules { inherit inputs; };
  inherit ((inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ modules.default ./testing/vm.nix ];
  }).config.system.build) vm;
}
