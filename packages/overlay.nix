{ inputs, lib }:
_: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
  packages = import ./default.nix {
    inherit inputs lib system;
    pkgs = prev;
  };
in
packages.overlay
// {
  kdePackages = prev.kdePackages // {
    applet-window-buttons6 = prev.kdePackages.applet-window-buttons6.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../patches/applet-window-buttons6-pr31.patch ];
    });
  };
}
