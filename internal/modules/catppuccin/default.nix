{ inputs, ... }:
{
  config,
  lib,
  pkgs,
  garuda-lib,
  ...
}:
with garuda-lib;
let
  catppuccin-settings = pkgs.stdenvNoCC.mkDerivation {
    pname = "catppuccin-settings";
    version = "0.0.4";
    src = ./src;
    installPhase = ''
      runHook preInstall
      install -d $out/skel
      cp -ar skel/{.config,.local} $out/skel
      install -d $out/share
      cp -ar share/{konsole,plasma,wallpapers} $out/share
      runHook postInstall
    '';
    meta = with lib; {
      description = "Garuda NixOS flake Catppuccin NixOS configs";
      homepage = "https://garudalinux.org";
      license = licenses.gpl3Only;
      maintainers = [ maintainers.dr460nf1r3 ];
      platforms = platforms.all;
    };
  };
  cfg = config.garuda.catppuccin;
in
{
  imports = [
    ./apps.nix
    inputs.catppuccin.nixosModules.catppuccin
  ];

  options = {
    garuda.catppuccin = {
      enable = lib.mkOption {
        default = false;
        example = true;
        description = ''
          Catppuccin Mocha edition: consistent pastel theming across the
          desktop and applications via catppuccin/nix.
        '';
        type = lib.types.bool;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.garuda.mokka.enable;
        message = "garuda.catppuccin and garuda.mokka cannot be enabled at the same time.";
      }
      {
        assertion = !config.garuda.dr460nized.enable;
        message = "garuda.catppuccin and garuda.dr460nized cannot be enabled at the same time.";
      }
    ];

    garuda.system.type = "catppuccin";

    garuda.kde.themePackage = catppuccin-settings;

    garuda.home-manager.modules = [
      (import ./dotfiles.nix {
        hmModule = inputs.catppuccin.homeModules.catppuccin;
      })
    ];

    environment.systemPackages = [ catppuccin-settings ];

    catppuccin = {
      autoEnable = gDefault true;
      enable = gDefault true;
    };
  };
}
