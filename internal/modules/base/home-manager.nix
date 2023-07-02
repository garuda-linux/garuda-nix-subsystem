{ config
, home-manager
, ...
}:
{
  # Load home-manager configurations
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  # Load home-manager configurations for every existing user
  home-manager.users = builtins.mapAttrs
    (name: user: {
      imports = [ ./dotfiles.nix ];
    })
    (builtins.filter (name: user: user.exists) (builtins.attrNames config.users));
}

