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

  # Load home-manager configurations for every existing user - to-do
  home-manager.users."nico".imports = [
    ./dotfiles.nix
  ];
}

