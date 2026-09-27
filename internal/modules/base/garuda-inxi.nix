{
  config,
  lib,
  pkgs,
  garuda-lib,
  ...
}:
let
  inherit (pkgs) garuda-inxi;

  isSimple = v: lib.isBool v || lib.isInt v || lib.isString v;
  isWalkable = v: lib.isAttrs v && !lib.isDerivation v;
  filterAttrsRecursive =
    attrs:
    let
      pairs = map (n: {
        inherit n;
        r = builtins.tryEval attrs.${n};
      }) (lib.attrNames attrs);
      good = lib.filter (p: p.r.success && (isSimple p.r.value || isWalkable p.r.value)) pairs;
    in
    lib.listToAttrs (
      map (p: {
        name = p.n;
        value = if isWalkable p.r.value then filterAttrsRecursive p.r.value else p.r.value;
      }) good
    );
  enabledOptions = filterAttrsRecursive config.garuda;
in
{
  config = {
    environment.systemPackages = [ garuda-inxi ];

    # Machine-readable dump of enabled garuda.* options for garuda-inxi.
    environment.etc."garuda-nix/enabled-options".text = lib.concatStringsSep "\n" (
      lib.filter (s: s != "") (
        lib.collect lib.isString (
          lib.mapAttrsRecursive (
            p: v: if v == true then "garuda.${lib.concatStringsSep "." p}" else ""
          ) enabledOptions
        )
      )
    );

    environment.etc."garuda-nix/subsystem-version".text = toString garuda-lib.version;
  };
}
