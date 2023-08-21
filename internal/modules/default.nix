{ inputs, lib, ... }@fromFlakes:
let
  modulesPerFile = {
    base = import ./base { inherit inputs; flake-lib = lib; };
    dr460nized = import ./dr460nized;
  };

  default = { ... }: {
    imports = [ inputs.chaotic.nixosModules.default inputs.home-manager.nixosModules.home-manager ] ++ builtins.attrValues modulesPerFile;
  };
in
modulesPerFile // { inherit default; }
