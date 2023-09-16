{ config
, lib
, utils
, garuda-lib
, ...
}:
with garuda-lib;
let
  cfg = config.garuda.home-manager;
  state_version = config.system.stateVersion;
  users = lib.attrsets.filterAttrs (_name: user: user.isNormalUser) config.users.users;
in
{
  options.garuda.home-manager.modules = with lib; mkOption {
    default = [ ];
    description = "List of home-manager configurations to include for all users.";
    example = "./dotfiles.nix";
    internal = true;
    type = types.listOf types.path;
  };

  config = {
    home-manager = {
      # Make home-manager use the same Nixpkgs as the rest of the system
      useGlobalPkgs = true;
      # Maps each user to a home-manager configuration
      users = builtins.mapAttrs
        (username: user:
          { ... }: {
            home.homeDirectory = user.home;
            home.stateVersion = state_version;
            home.username = username;

            imports = cfg.modules;
          }
        )
        users;
    };

    # Creates a systemd service for each user that runs home-manager
    systemd.services = lib.mapAttrs'
      (username: _user: lib.nameValuePair "home-manager-${utils.escapeSystemdPath username}" {
        after = [ "create-homedirs.service" ];
      })
      users;

    # This is the default home-manager configuration
    garuda.home-manager.modules = gExcludableArray config "home-manager-modules" [ ./dotfiles.nix ];
  };
}
