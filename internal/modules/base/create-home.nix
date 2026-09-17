{
  config,
  lib,
  pkgs,
  garuda-lib,
  ...
}:
let
  cfg = config.garuda.create-home;
  impermanence = config.garuda.impermanence.enable;
  seedCommand = if impermanence then "seed_home_if_unseeded" else "create_home_if_empty";
in
with garuda-lib;
{
  options.garuda.create-home = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.garuda.system.isGui;
      internal = true;
    };
    skel = lib.mkOption {
      type = lib.types.str;
      description = "The directory containing the skeleton files to copy into the user's home directory.";
      internal = true;
      default = "/etc/skel";
    };
  };
  config = {
    systemd.services.create-homedirs = lib.mkIf cfg.enable {
      enable = gDefault true;
      wantedBy = [ "multi-user.target" ];
      before = [ "multi-user.target" ];
      unitConfig = lib.mkIf impermanence {
        RequiresMountsFor = "/home";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${
          if impermanence then
            ''
              # Impermanence pre-creates non-empty home directories, so seed
              # skeleton files exactly once per user instead.
              function seed_home_if_unseeded {
                marker="$1/.local/share/garuda-skel.seeded"

                if [ -e "$marker" ]; then
                  echo "Home directory for $2 already seeded"
                  return 0
                fi

                uid="$(id -u "$2")"
                gid="$(id -g "$2")"
                install -d -m 755 -o "$uid" -g "$gid" "$1" "$1/.local/share"
                "${pkgs.rsync}/bin/rsync" -a --ignore-existing "${cfg.skel}/" "$1/"
                chown -R "$uid:$gid" "$1"
                install -m 644 -o "$uid" -g "$gid" /dev/null "$marker"
                echo "Seeded home directory for $2"
              }
            ''
          else
            ''
              set -e
              # Create home directory if necessary
              function create_home_if_empty {
                [ -z "$(ls -A "$1")" ] && rm -r "$1" && "${pkgs.linux-pam}/bin/mkhomedir_helper" "$2" 0022 "${cfg.skel}" && echo "Created home directory for $2" || echo "Home directory for $2 already exists"
              }
            ''
        }
        ${lib.strings.concatLines (
          lib.mapAttrsToList (name: user: ''
            ${seedCommand} "${user.home}" "${name}"
          '') (lib.attrsets.filterAttrs (_name: user: user.isNormalUser) config.users.users)
        )}
      '';
    };
  };
}
