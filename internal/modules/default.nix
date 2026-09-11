{
  inputs,
  lib,
  overlay,
  ...
}:
let
  modulesPerFile = {
    base = import ./base {
      inherit inputs overlay;
      flake-lib = lib;
    };
    catppuccin = import ./catppuccin {
      inherit inputs;
      flake-lib = lib;
    };
    dr460nized = import ./dr460nized;
  };

  default =
    { ... }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ]
      ++ builtins.attrValues modulesPerFile;
    };
in
modulesPerFile // { inherit default; }
