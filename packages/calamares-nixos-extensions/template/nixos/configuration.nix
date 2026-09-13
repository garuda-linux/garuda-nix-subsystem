# This is your system's configuration file.
# Use this to configure your system environment.
{
  inputs,
  pkgs,
  ...
}:
{
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # inputs.self.nixosModules.example

    # Chaotic Nyx and home-manager are already preconfigured by garudaSystem,
    # no need to add it to profit from it!
    # https://www.nyx.chaotic.cx
    # https://home-manager-options.extranix.com

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      inputs.self.overlays.additions
      inputs.self.overlays.modifications

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default
    ];
  };

  # Garuda Nix edition and features, as picked in the installer.
  # @@GARUDA@@

  # Hardware auto-detected with nixos-facter during installation.
  # @@FACTER@@

  # @@BOOTLOADER@@

  # @@SYSTEM@@

  # @@USER@@

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "@STATEVERSION@";
}
