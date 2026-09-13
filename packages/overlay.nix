{ inputs, lib }:
_: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
  packages = import ./default.nix {
    inherit inputs lib system;
    pkgs = prev;
  };

  withZenpower =
    lfinal:
    lfinal.extend (
      lpFinal: _lpPrev: {
        zenpower = lpFinal.callPackage ./zenpower5 { };
      }
    );
in
{
  inherit (packages.internal)
    calamares-nixos-extensions
    garuda-nix-manager
    ;

  calamares-nixos = prev.calamares-nixos.override {
    calamares = packages.internal.calamares;
    "calamares-nixos-extensions" = packages.internal.calamares-nixos-extensions;
  };

  linuxPackagesFor = kernel: withZenpower (prev.linuxPackagesFor kernel);
  linuxPackages_cachyos = withZenpower (
    prev.linuxPackages_cachyos or (prev.linuxPackagesFor prev.linuxPackages.kernel)
  );
}
// {
  kdePackages = prev.kdePackages // {
    applet-window-buttons6 = prev.kdePackages.applet-window-buttons6.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../patches/applet-window-buttons6-pr31.patch ];
    });
  };
}
