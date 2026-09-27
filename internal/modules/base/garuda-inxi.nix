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
    lib.mapAttrs (_: v: if lib.isAttrs v then filterAttrsRecursive v else v) (
      lib.filterAttrs (_: v: isSimple v || lib.isAttrs v) attrs
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
