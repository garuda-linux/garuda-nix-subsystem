{ inputs, nixpkgs, internal, ... }@fromFlake:
rec {
  garuda-lib = import ./garuda-lib.nix { inherit inputs nixpkgs fromFlake; };

  garudaSystem = args: nixpkgs.lib.nixosSystem (args // {
    extraModules = [ internal.modules.default ] ++ args.extraModules or [ ];
    specialArgs = {
      inherit garuda-lib;
    } // args.specialArgs or { };
  });
  nixosSystem = garudaSystem;
}
