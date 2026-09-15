{
  config,
  garuda-lib,
  lib,
  pkgs,
  ...
}:
with garuda-lib;
{
  options.garuda.flatpak.enable = lib.mkEnableOption "Flatpak with the Flathub remote pre-added";

  config = lib.mkIf config.garuda.flatpak.enable {
    services.flatpak.enable = gDefault true;

    xdg.portal = {
      enable = gDefault true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    systemd.services.flatpak-add-flathub = {
      wantedBy = gDefault [ "multi-user.target" ];
      serviceConfig.Type = gDefault "oneshot";
      script = gDefault ''
        ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub \
          https://dl.flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
