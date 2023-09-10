{ inputs, lib, ... }:
let
  modulesPerFile = {
    base = import ./base { inherit inputs; flake-lib = lib; };
    dr460nized = import ./dr460nized;
  };

  default = { ... }: {
    imports = [
      inputs.chaotic-nyx.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index
      inputs.spicetify-nix.nixosModule
    ] ++ builtins.attrValues modulesPerFile;
  };
in
modulesPerFile // { inherit default; }
