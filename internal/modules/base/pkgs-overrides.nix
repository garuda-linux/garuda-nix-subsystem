{ lib, ... }:
{
  config = {
    nixpkgs.overlays = lib.mkAfter [
      (_: prev-pkgs: {
        discord = prev-pkgs.discord-krisp;
      })
    ];
  };
}
