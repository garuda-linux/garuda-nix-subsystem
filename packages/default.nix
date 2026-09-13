{
  inputs,
  lib,
  pkgs,
  system,
}:
rec {
  # Packages that are used internally by Garuda Linux only
  internal = {
    installer = pkgs.callPackage ./gns-management/installer.nix {
      all-packages = pkgs;
      garuda-lib = lib;
      inherit system;
    };
    garuda-update = pkgs.callPackage ./gns-management/gns-update.nix {
      all-packages = pkgs;
      garuda-lib = lib;
      inherit system;
      inherit (inputs) self;
    };
    garuda-nix-manager = pkgs.qt6Packages.callPackage ./garuda-nix-manager {
      inherit (internal) launch-terminal;
    };
    launch-terminal = pkgs.callPackage ./garuda-libs {
      inherit pkgs;
    };
    calamares-nixos-extensions = pkgs.callPackage ./calamares-nixos-extensions { };
  };

  # Packages that are available in the flake's packages output
  external = {
    inherit (internal) calamares-nixos-extensions;
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
      calamares-nixos-extensions
      ;
  };
}
