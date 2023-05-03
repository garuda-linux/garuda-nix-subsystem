{ inputs, ... }@fromFlakes:
let
  modulesPerFile = {
    base = import ./base fromFlakes;
    dr460nized = import ./dr460nized fromFlakes;
  };

  default = { ... }: {
    imports = builtins.attrValues modulesPerFile ++ [ inputs.chaotic.nixosModules.default ];
  };
in
modulesPerFile // { inherit default; }
