{ inputs
, nixpkgs
, self ? inputs.self
, formatter
}:

# The following shells are used to help our maintainers and CI/CDs.
let
  mkShells = final: prev:
    let
      overlayFinal = prev // final // { callPackage = prev.newScope final; };
      inherit (prev.stdenv.hostPlatform) system;
    in
    {
      default = overlayFinal.mkShell {
        buildInputs = [ formatter."${system}" ];
      };
    };
in
{
  x86_64-linux = mkShells inputs.chaotic.packages.x86_64-linux
    nixpkgs.legacyPackages.x86_64-linux;
  aarch64-linux = mkShells inputs.chaotic.packages.aarch64-linux
    nixpkgs.legacyPackages.aarch64-linux;
}
