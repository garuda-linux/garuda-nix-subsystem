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

  boot-test = lib.mkBootTest {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    garuda-modules = modules.default;
  };

  iso-dr460nized = lib.mkISO "dr460nized";
  iso-mokka = lib.mkISO "mokka";
  iso-catppuccin = lib.mkISO "catppuccin";
}
