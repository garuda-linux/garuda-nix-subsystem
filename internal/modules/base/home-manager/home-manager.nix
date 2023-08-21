{ config
, lib
, utils
, garuda-lib
, ...
}:
with garuda-lib;
let
  users = (lib.attrsets.filterAttrs (name: user: user.isNormalUser) config.users.users);
in
{
  # Load home-manager configurations for every existing user - to-do
  home-manager = {
    useGlobalPkgs = true;

    users = builtins.mapAttrs
    (username: user:
      (import ./dotfiles.nix
        {
          username = username;
          home = user.home;
          state_version = config.system.stateVersion;
        }))
    users;
  };

  systemd.services = lib.mapAttrs' (username: user: lib.nameValuePair ("home-manager-${utils.escapeSystemdPath username}") {
    after = [ "create-homedirs.service" ];
  }) users;
}

