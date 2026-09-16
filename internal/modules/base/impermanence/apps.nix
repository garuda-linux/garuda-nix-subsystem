{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.garuda.impermanence;

  knownApps = {
    networkmanager = {
      condition = config.networking.networkmanager.enable;
      dirs = [
        "/var/lib/NetworkManager"
        "/etc/NetworkManager/system-connections"
      ];
    };
    bluetooth = {
      condition = config.hardware.bluetooth.enable;
      dirs = [ "/var/lib/bluetooth" ];
    };
    iwd = {
      condition = config.networking.wireless.iwd.enable;
      dirs = [
        {
          directory = "/var/lib/iwd";
          mode = "u=rwx,g=,o=";
        }
      ];
    };
    docker = {
      condition = config.virtualisation.docker.enable;
      dirs = [ "/var/lib/docker" ];
      userDirs = [ ".docker" ];
    };
    podman = {
      condition = config.virtualisation.podman.enable;
      dirs = [ "/var/lib/containers" ];
    };
    libvirt = {
      condition = config.virtualisation.libvirtd.enable;
      dirs = [ "/var/lib/libvirt" ];
    };
    nspawn = {
      dirs = [ "/var/lib/machines" ];
    };
    flatpak = {
      condition = config.garuda.flatpak.enable || config.services.flatpak.enable;
      dirs = [ "/var/lib/flatpak" ];
      userDirs = [ ".var" ];
    };
    fwupd = {
      condition = config.services.fwupd.enable;
      dirs = [ "/var/lib/fwupd" ];
    };
    upower = {
      condition = config.services.upower.enable;
      dirs = [ "/var/lib/upower" ];
    };
    plasmalogin = {
      condition = config.services.displayManager.plasma-login-manager.enable;
      dirs = [ "/var/lib/plasmalogin" ];
    };
    accountsservice = {
      condition = config.services.accounts-daemon.enable;
      dirs = [ "/var/lib/AccountsService" ];
    };
    printing = {
      condition = config.garuda.printing.enable || config.services.printing.enable;
      dirs = [ "/etc/cups" ];
    };
    samba = {
      condition = config.garuda.samba.enable;
      dirs = [ "/var/lib/samba" ];
    };
    fprintd = {
      condition = config.services.fprintd.enable;
      dirs = [ "/var/lib/fprint" ];
    };
    geoclue = {
      condition = config.services.geoclue2.enable;
      dirs = [ "/var/lib/geoclue" ];
    };
    modemmanager = {
      condition =
        lib.hasAttrByPath [ "networking" "modemmanager" ] config && config.networking.modemmanager.enable;
      dirs = [ "/var/lib/ModemManager" ];
    };
    firefox = {
      userDirs = [ ".mozilla" ];
    };
    thunderbird = {
      userDirs = [ ".thunderbird" ];
    };
    steam = {
      condition = config.programs.steam.enable;
      userDirs = [
        ".steam"
        ".local/share/Steam"
      ];
    };
    rust = {
      userDirs = [
        ".cargo"
        ".rustup"
      ];
    };
  };

  autoEnabled = lib.filterAttrs (_name: app: (app.condition or false)) knownApps;
  selected = lib.unique (builtins.attrNames autoEnabled ++ cfg.apps);
  selectedApps = map (name: knownApps.${name}) selected;

  appDirs = lib.concatMap (app: app.dirs or [ ]) selectedApps;
  appFiles = lib.concatMap (app: app.files or [ ]) selectedApps;
  appUserDirs = lib.concatMap (app: app.userDirs or [ ]) selectedApps;
  appUserFiles = lib.concatMap (app: app.userFiles or [ ]) selectedApps;
in
{
  options.garuda.impermanence.apps = lib.mkOption {
    type = lib.types.listOf (lib.types.enum (builtins.attrNames knownApps));
    default = [ ];
    description = "Known apps whose state persists. Service apps enable automatically.";
  };

  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (options.environment ? persistence) {
      environment.persistence."/persist" = {
        directories = appDirs;
        files = appFiles;
        users = lib.genAttrs cfg.persistentUsers (_name: {
          directories = appUserDirs;
          files = appUserFiles;
        });
      };
    }
  );
}
