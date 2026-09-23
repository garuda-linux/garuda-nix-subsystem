# This is your home-manager configuration file
# Use this to configure your home environment.
# (On NixOS this is imported per user from nixos/configuration.nix
# via home-manager.users."<name>".)
{
  ...
}:
{
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager),
    # add them to nixos/configuration.nix via garuda.home-manager.modules.

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default
    # (needs `inputs` passed through home-manager.extraSpecialArgs first)

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  home = {
    username = "@USERNAME@";
    homeDirectory = "/home/@USERNAME@";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  # home.packages = with pkgs; [ steam ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "@STATEVERSION@";
}
