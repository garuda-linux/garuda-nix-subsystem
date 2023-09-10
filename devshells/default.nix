{ inputs
, nixpkgs
, self ? inputs.self
, formatter
, lib
}:

# The following shells are used to help our maintainers and CI/CDs.
let
  mkShells = final: prev:
    let
      overlayFinal = prev // final // { callPackage = prev.newScope final; };
      inherit (prev.stdenv.hostPlatform) system;
      installer = overlayFinal.callPackage ./installer.nix
        {
          all-packages = overlayFinal;
          garuda-lib = lib;
          inherit system;
        };
      garuda-update = overlayFinal.callPackage ./gns-update.nix
        {
          all-packages = overlayFinal;
          garuda-lib = lib;
          inherit system self;
        };
    in
    {
      default = overlayFinal.mkShell {
        buildInputs = [ formatter."${system}" ];
      };
      gns-install = overlayFinal.mkShell {
        buildInputs = [ installer garuda-update ];
      };
      gns-update = overlayFinal.mkShell {
        buildInputs = [ garuda-update ];
      };
    };
in
{
  x86_64-linux = mkShells inputs.chaotic-nyx.packages.x86_64-linux
    nixpkgs.legacyPackages.x86_64-linux;
  aarch64-linux = mkShells inputs.chaotic-nyx.packages.aarch64-linux
    nixpkgs.legacyPackages.aarch64-linux;
}
