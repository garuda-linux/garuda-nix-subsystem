{ config, lib, pkgs, garuda-lib, ... }:
let
  cfg = config.garuda.create-home;
in
with garuda-lib;
{
  options.garuda.create-home = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
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
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -e
        # Create home directory if necessary
        function create_home_if_empty {
          [ -z "$(ls -A "$1")" ] && rm -r "$1" && "${pkgs.linux-pam}/bin/mkhomedir_helper" "$2" 0022 "${cfg.skel}" && echo "Created home directory for $2" || echo "Home directory for $2 already exists"
        }
        ${
          lib.strings.concatLines (lib.mapAttrsToList (name: user: ''
            create_home_if_empty "${user.home}" "${name}" 
          '') (lib.attrsets.filterAttrs (name: user: user.isNormalUser) config.users.users))
        }
      '';
    };
  };
}
