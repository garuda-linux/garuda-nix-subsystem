{ inputs, lib }:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  evaluated = lib.garudaSystem {
    system = "x86_64-linux";
    modules = [ ];
  };
  json = pkgs.nixosOptionsDoc {
    inherit (evaluated) options;
    warningsAreErrors = false;
  };
in
pkgs.runCommand "garuda-options.md"
  {
    inherit (json) optionsJSON;
  }
  ''
    ${pkgs.python3}/bin/python3 ${./options-doc.py} \
      "$optionsJSON/share/doc/nixos/options.json" > $out
  ''
