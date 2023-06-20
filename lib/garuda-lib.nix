{ nixpkgs, ... }@fromFlake: { config, pkgs, lib, ... }:
rec {
  # gDefault, set a priority of 950, which should be our default so the user can override our settings, yet we can override nixpkgs
  gDefault = arg: lib.mkOverride 950 arg;
  # Remove excluded options from the output array
  gExcludableArray = name: array: lib.filter 
                                (x: !(config.garuda.excludes."${name}".excludeAll or false) &&
                                    !(lib.lists.any (y: builtins.unsafeDiscardStringContext x == builtins.unsafeDiscardStringContext y) (config.garuda.excludes."${name}".exclude or []))
                                    ) array;
  # Define options = [] for the exclusion variable
  gCreateExclusionOption = name: { "${name}" = {
    excludeAll = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Exclude everything under exclusion variable ${name}";
    };
    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
      description = "Exclude packages/strings under exclusion variable ${name}";
    };
  }; };
}