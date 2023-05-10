{ inputs, ... }@fromFlakes:
let
  modulesPerFile = {
    base = import ./base fromFlakes;
    dr460nized = import ./dr460nized;
  };

  default = { ... }: {
    imports = [ inputs.chaotic.nixosModules.default ] ++ builtins.attrValues modulesPerFile;
  };
in
modulesPerFile // { inherit default; }
