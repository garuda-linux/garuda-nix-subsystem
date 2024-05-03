{ inputs, lib, overlay, ... }:
let
  modulesPerFile = {
    base = import ./base { inherit inputs overlay; flake-lib = lib; };
    catppuccin = import ./catppuccin { inherit inputs; flake-lib = lib; };
    dr460nized = import ./dr460nized;
  };

  default = { ... }: {
    imports = [
      inputs.chaotic-nyx.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index
    ] ++ builtins.attrValues modulesPerFile;
  };
in
modulesPerFile // { inherit default; }
