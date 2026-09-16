{
  inputs,
  lib,
  overlay,
  ...
}@fromFlake:
let
  modules = import ./modules {
    inherit
      inputs
      lib
      fromFlake
      overlay
      ;
  };

  mkBootTestFor =
    edition:
    lib.mkBootTest {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      garuda-modules = modules.default;
      inherit edition;
    };
in
{
  inherit modules;
  vm = lib.mkVm "dr460nized" [ ];

  ci-bare = lib.mkCiVm "dr460nized" [ ];
  ci-full = lib.mkCiVm "catppuccin" [
    {
      garuda.gaming.enable = true;
      garuda.performance-tweaks.enable = true;
    }
  ];

  options-doc = import ./options-doc { inherit inputs lib; };

  boot-test-mokka = mkBootTestFor "mokka";
  boot-test-dr460nized = mkBootTestFor "dr460nized";
  boot-test-catppuccin = mkBootTestFor "catppuccin";

  installer-test = import ./testing/installer-test.nix {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  };

  installer-eval-test = import ./testing/installer-eval-test.nix {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    inherit inputs;
  };

  installer-install-test = import ./testing/installer-install-test.nix {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    inherit inputs;
  };

  iso-dr460nized = lib.mkISO "dr460nized";
  iso-mokka = lib.mkISO "mokka";
  iso-catppuccin = lib.mkISO "catppuccin";
}
