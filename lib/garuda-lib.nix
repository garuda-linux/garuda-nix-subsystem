{ nixpkgs, ... }:
let
  inherit (nixpkgs) lib;
  # gDefault, set a priority of 950, which should be our default so the user can override our settings, yet we can override nixpkgs
  gDefault = lib.mkOverride 950;
  # This is terrible, but a perfect example of the sunk cost fallacy
  isUniqueVariable = type:
    let
      uniqueTypes = [ "bool" "str" "raw" "int" "float" "number" "nonEmptyStr" "package" "pkgs" "path" "uniq" "unique" "enum" "intBetween" ];
      uniqueTypeSpecial = [ "strMatching " "unsignedInt" "signedInt" ];
    in
    if builtins.elem type.name uniqueTypes then
      true
    else if builtins.any (x: lib.strings.hasPrefix x type.name) uniqueTypeSpecial then
      true
    else
      false;

  isNonUniqueVariable = type:
    let
      nonUnique = [ "listOf" "attrsOf" "lazyAttrsOf" ];
    in
    if builtins.elem type.name nonUnique then
      true
    else
      false;

  setDefaultAttrs = path: options: value:
    let
      attrbypath = lib.attrByPath path null options;
      combined_path = lib.showOption path;
    in
    # Already overridden
    if builtins.trace combined_path value ? _type && value._type == "override" then
      if !(attrbypath ? type) || isNonUniqueVariable attrbypath.type then
        builtins.trace "nonUnique variable ${combined_path} used with an override, be careful!" value
      else
        value
    # This is an attribute, recurse
    else if lib.isAttrs value then
      lib.mapAttrs (name: innerValue: setDefaultAttrs (path ++ [ name ]) options innerValue) value
    # This is a value
    else if attrbypath != null && builtins.trace (isUniqueVariable attrbypath.type) false then
      gDefault value
    else
      value;
in
{
  inherit gDefault;
  # Remove excluded options from the output array
  gExcludableArray = config: name: lib.filter
    (x: !(config.garuda.excludes."${name}".excludeAll or false) &&
      !(lib.lists.any (y: builtins.unsafeDiscardStringContext x == builtins.unsafeDiscardStringContext y) (config.garuda.excludes."${name}".exclude or [ ]))
    );
  # Define options = [] for the exclusion variable
  gCreateExclusionOption = name: {
    "${name}" = {
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
    };
  };
  gDefaultAttrs = setDefaultAttrs [ ];
  # Subsystem version
  version = 1;
  # Generate /etc/skel from a path. This ensures that certain directories are always available to mount from with the correct permissions.
  gGenerateSkel = pkgs: skel: name: derivation {
    name = "skel-${name}";
    src = skel;
    builder = pkgs.writeShellScript "build-skel-${name}" ''
      PATH="${pkgs.rsync}/bin:${pkgs.coreutils}/bin"
      set -e
      mkdir -p "$out/"{.cache,.config,.local/share}
      rsync -a "$src/" "$out"
    '';
    inherit (pkgs.hostPlatform) system;
  };
}
