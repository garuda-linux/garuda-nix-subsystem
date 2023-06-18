{ inputs, nixpkgs, internal, ... }@fromFlake:
rec {
  garudaSystem = args: nixpkgs.lib.nixosSystem (args // {
    modules = [ internal.modules.default ] ++ args.modules;
  });
  nixosSystem = garudaSystem;
}
