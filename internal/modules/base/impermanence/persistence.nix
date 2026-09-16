{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.garuda.impermanence;

  lockedDirs = [
    {
      directory = ".gnupg";
      mode = "0700";
    }
    {
      directory = ".ssh";
      mode = "0700";
    }
  ];

  userDirs = lockedDirs ++ [
    {
      directory = ".local/share/keyrings";
      mode = "0700";
    }
    ".config"
    ".local/share"
    ".local/state"
  ];
in
{
  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (options.environment ? persistence) {
      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [
          "/etc/nixos"
          "/var/lib/systemd"
          "/var/lib/nixos"
          "/var/lib/alsa"
          "/var/lib/colord"
          "/var/spool"
        ];
        files = [
          "/etc/machine-id"
          "/etc/adjtime"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
        ];
        users = {
          "root" = {
            directories = lockedDirs;
          };
        }
        // (lib.genAttrs cfg.persistentUsers (_name: {
          directories = userDirs;
        }));
      };

      security.sudo.extraConfig = ''
        Defaults lecture = never
      '';
    }
  );
}
