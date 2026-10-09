{
  config,
  lib,
  utils,
  garuda-lib,
  ...
}:
with garuda-lib;
let
  cfg = config.garuda.home-manager;
  state_version = config.system.stateVersion;
in
{
  options.garuda = {
    home-manager.modules =
      with lib;
      mkOption {
        default = [ ];
        description = "List of home-manager configurations to include for all users.";
        example = "./dotfiles.nix";
        internal = true;
        type = types.listOf types.deferredModule;
      };
    excludes = gCreateExclusionOption "home-manager-modules";
  };

  config = {
    home-manager = {
      # Make home-manager use the same Nixpkgs as the rest of the system
      useGlobalPkgs = true;

      # Install home.packages into /etc/profiles/per-user, part of the system closure
      useUserPackages = gDefault true;
      extraSpecialArgs = { inherit garuda-lib; };

      # Defaults for every configured user. Shared modules rather than a
      # home-manager.users mapping over users.users: with useUserPackages,
      # home-manager defines users.users.<name>.packages from home-manager.users,
      # so deriving the user set from users.users recurses infinitely.
      sharedModules = [
        {
          home.stateVersion = state_version;

          imports = cfg.modules;
        }
      ];
    };

    # Orders each configured user's home-manager service after home creation
    systemd.services = lib.mapAttrs' (
      username: _user:
      lib.nameValuePair "home-manager-${utils.escapeSystemdPath username}" {
        after = [ "create-homedirs.service" ];
      }
    ) config.home-manager.users;

    # This is the default home-manager configuration
    garuda.home-manager.modules = gExcludableArray config "home-manager-modules" [
      (lib.mkBefore ./dotfiles.nix)
    ];

    # Backup files with a .bak extension, ensure not failing activation because of this
    home-manager.backupFileExtension = "bak";
  };
}
