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
  filterAttrsRecursive =
    attrs:
    lib.foldlAttrs (
      acc: n: v:
      let
        r = builtins.tryEval v;
      in
      if !r.success then
        acc
      else if lib.isAttrs r.value && !lib.isDerivation r.value then
        acc // { ${n} = filterAttrsRecursive r.value; }
      else if isSimple r.value then
        acc // { ${n} = r.value; }
      else
        acc
    ) { } attrs;

  # Skip renamed-option aliases: reading them traces an "Obsolete option" warning
  enabledOptions = filterAttrsRecursive (
    config.garuda // { subsystem = removeAttrs config.garuda.subsystem [ "config" ]; }
  );
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
