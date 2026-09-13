{ config, lib, ... }:
with lib;
let
  cfg = config.garuda.subsystem.imported-users;
  submoduleOptions = {
    options = {
      home = mkOption {
        type = types.str;
        description = "Home directory of the imported user, e.g. /home/garuda.";
      };
      passwordHash = mkOption {
        type = types.str;
        description = "Hashed initial password, used as initialHashedPassword.";
      };
      uid = mkOption {
        type = types.int;
        description = "Numeric UID, kept identical to the Garuda host user.";
      };
      wheel = mkOption {
        type = types.bool;
        description = "Whether the imported user gets wheel (sudo) membership.";
      };
    };
  };
in
{
  options.garuda.subsystem.imported-users = {
    users = mkOption {
      type = types.attrsOf (types.submodule submoduleOptions);
      default = { };
      description = ''
        User accounts imported from the Garuda host (populated from
        garuda-managed.json), keyed by username. Each entry recreates
        the host user witht the same UID, home and admin rights inside NixOS.
      '';
    };
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Recreate the Garuda host users inside this system. Disable to
        manage users purely via users.users instead.
      '';
    };
    shared-home = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Share the imported users' ~/.config, ~/.local and ~/.cache
          between the Garuda host home and the NixOS home via bind
          mounts, so app settings carry over to the subsystem.
        '';
      };
      uuid = mkOption {
        type = types.str;
        description = ''
          UUID of the Garuda BTRFS filesystem holding the @home
          subvolume that the shared home directories are mounted from.
          Set automatically from garuda-managed.json.
        '';
      };
    };
  };

  config = lib.mkIf (cfg.enable && config.garuda.subsystem.enable) {
    users.users = mapAttrs (_name: value: {
      isNormalUser = true;
      inherit (value) uid;
      initialHashedPassword = value.passwordHash;
      extraGroups = lib.mkIf value.wheel [ "wheel" ];
    }) cfg.users;
  };
}
