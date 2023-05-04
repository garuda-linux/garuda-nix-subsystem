{ inputs, nixpkgs, internal, ... }@fromFlake:
{
  garudaSystem = args: nixpkgs.lib.nixosSystem (args // {
    modules = [ internal.modules.default ] ++ args.modules;
  });
}
