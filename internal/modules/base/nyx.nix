{ config, lib, flake-inputs, ... }:
let
  cfg = config.garuda.chaotic-nyx.cache;
in
with lib;
{
  options = {
    garuda.chaotic-nyx.cache.enable =
      mkOption {
        default = true;
        description = ''
          If set to true, chaotic's nyx will have its binary cache automatically enabled and managed.
        '';
      };
  };
  config = {
    nix.settings = mkIf cfg.enable {
      extra-substituters = [ "https://nyx.chaotic.cx" ];
      extra-trusted-public-keys = [
        "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      ];
    };
  };
}
