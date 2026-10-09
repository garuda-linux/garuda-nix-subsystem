{ inputs, lib }:
final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;

  # NOTE: `lib` here is garuda-lib, not nixpkgs.lib, use nixlib for nixpkgs helpers.
  nixlib = inputs.nixpkgs.lib;

  packages = import ./default.nix {
    inherit inputs lib system;
    pkgs = final;
  };

in
{
  inherit (packages.internal)
    calamares-nixos-extensions
    garuda-inxi
    garuda-nix-manager
    garuda-nix-subsystem
    ;

  calamares-nixos = prev.calamares-nixos.override {
    calamares = packages.internal.calamares;
    "calamares-nixos-extensions" = packages.internal.calamares-nixos-extensions;
  };

  linuxPackages_cachyos =
    (prev.linuxPackages_cachyos or (prev.linuxPackagesFor prev.linuxPackages.kernel)).extend
      (
        _lpFinal: lpPrev:
        nixlib.optionalAttrs (lpPrev ? zenpower) {
          zenpower = lpPrev.zenpower.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ../patches/zenpower-clang-fixes.patch ];
          });
        }
      );
}
// {
  kdePackages = prev.kdePackages // {
    applet-window-buttons6 = prev.kdePackages.applet-window-buttons6.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../patches/applet-window-buttons6-pr31.patch ];
    });
  };
}
