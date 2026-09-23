{
  inputs,
  lib,
  pkgs,
  system,
}:
rec {
  # Packages that are used internally by Garuda Linux only
  internal = {
    garuda-installer-lib = pkgs.callPackage ./garuda-installer-lib { };
    calamares-nixos-extensions = pkgs.callPackage ./calamares-nixos-extensions {
      inherit (internal) garuda-installer-lib;
    };
    calamares = pkgs.callPackage ./calamares { };
    garuda-nix-manager = pkgs.qt6Packages.callPackage ./garuda-nix-manager {
      inherit (internal) launch-terminal;
    };
    install-garuda-nix = pkgs.callPackage ./install-garuda-nix {
      inherit (internal) garuda-installer-lib;
    };
    garuda-fs-diff = pkgs.callPackage ./garuda-fs-diff { };
    installer = pkgs.callPackage ./gns-management/installer.nix {
      all-packages = pkgs;
      garuda-lib = lib;
      inherit system;
      inherit (internal) garuda-installer-lib;
    };
    launch-terminal = pkgs.callPackage ./garuda-libs {
      inherit pkgs;
    };
    garuda-update = pkgs.callPackage ./gns-management/gns-update.nix {
      all-packages = pkgs;
      garuda-lib = lib;
      inherit system;
      inherit (internal) garuda-installer-lib;
      inherit (inputs) self;
    };
  };

  # Packages that are available in the flake's packages output
  external = {
    inherit (internal) install-garuda-nix;
    docs =
      pkgs.runCommand "gns-docs"
        # makes the documentation available at ./result/ by running nix build .#docs
        {
          nativeBuildInputs = with pkgs; [
            bash
            mdbook
          ];
        }
        ''
          bash -c "errors=$(mdbook build -d $out ${./..}/docs |& grep ERROR)
          if [ \"$errors\" ]; then
              exit 1
          fi"
        '';
  };

  cached = {
    inherit (internal)
      installer
      garuda-update
      garuda-nix-manager
      launch-terminal
      garuda-installer-lib
      calamares-nixos-extensions
      install-garuda-nix
      ;
  };
}
