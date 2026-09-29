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
  tela-circle-icon-theme = prev.tela-circle-icon-theme.overrideAttrs (old: {
    version = "unstable-2026-08-16";
    src = final.fetchFromGitHub {
      owner = "vinceliuice";
      repo = "tela-circle-icon-theme";
      rev = "ee3cf47bcb05c3d99a0860b54254d2ff3d1d2c69";
      hash = "sha256-kvAJH/ptMvSCjk5Equi+8ZzHjSDKQUURUImNDZZXQcs=";
    };
    patches = (old.patches or [ ]) ++ [ ../patches/tela-circle-catppuccin.patch ];
    installPhase = ''
      runHook preInstall
      ./install.sh -d $out/share/icons standard catppuccin
      jdupes --quiet --link-soft --recurse $out/share
      runHook postInstall
    '';
    # Upstream rev ships dangling symlinks
    dontCheckForBrokenSymlinks = true;
  });

  kdePackages = prev.kdePackages // {
    applet-window-buttons6 = prev.kdePackages.applet-window-buttons6.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../patches/applet-window-buttons6-pr31.patch ];
    });
  };
}
