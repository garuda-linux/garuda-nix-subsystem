{ inputs, lib, pkgs, system }: rec {
  # Packages that are available for use both externally and as an overlay to normal nixpkgs
  overlay = {
    beautyline-icons = pkgs.callPackage ./beautyline-icons { };

    dr460nized-kde-theme = pkgs.callPackage ./dr460nized-kde-theme { inherit (overlay) beautyline-icons; };

    firedragon-bin-unwrapped = pkgs.callPackage ./firedragon-bin { };
    firedragon-bin = pkgs.wrapFirefox overlay.firedragon-bin-unwrapped {
      pname = "firedragon-bin";
      extraPoliciesFiles = [
        "${overlay.firedragon-bin-unwrapped}/lib/firedragon-bin-${overlay.firedragon-bin-unwrapped.version}/distribution/policies.json"
      ];
    };

    firedragon-catppuccin-bin-unwrapped = pkgs.callPackage ./firedragon-catppuccin-bin { };
    firedragon-catppuccin-bin = pkgs.wrapFirefox overlay.firedragon-catppuccin-bin-unwrapped {
      pname = "firedragon-catppuccin-bin";
      extraPoliciesFiles = [
        "${overlay.firedragon-catppuccin-bin-unwrapped}/lib/firedragon-catppuccin-bin-${overlay.firedragon-catppuccin-bin-unwrapped.version}/distribution/policies.json"
      ];
    };

    inherit (internal) garuda-nix-manager;
  };

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
  };

  # Packages that are available in the flake's packages output
  external = overlay // {
    docs = pkgs.runCommand "gns-docs"
      # makes the documentation available at ./result/ by running nix build .#docs
      { nativeBuildInputs = with pkgs; [ bash mdbook ]; }
      ''
        bash -c "errors=$(mdbook build -d $out ${./..}/docs |& grep ERROR)
        if [ \"$errors\" ]; then
            exit 1
        fi"
      '';
  };

  cached = {
    inherit (internal) installer garuda-update garuda-nix-manager launch-terminal;
    inherit (external) firedragon-bin firedragon-catppuccin-bin;
  };
}
