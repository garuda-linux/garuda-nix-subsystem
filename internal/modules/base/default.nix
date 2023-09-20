{ inputs, ... }: { flake-inputs
                 , config
                 , ...
                 }: {
  imports = [
    ./boot.nix
    ./create-home.nix
    ./gaming.nix
    ./garuda-update.nix
    ./hardware.nix
    ./home-manager/home-manager.nix
    ./locales.nix
    ./mount-garuda.nix
    ./networking.nix
    ./nix.nix
    ./nyx.nix
    ./performance.nix
    ./programs.nix
    ./services.nix
    ./shells.nix
    ./sound.nix
    ./subsystem/subsystem.nix
  ];

  # Pass inputs via flake-inputs to the modules
  _module.args.flake-inputs = inputs;

  # Custom label for boot menu entries
  system.nixos.label = builtins.concatStringsSep "-" [ "garuda-nix-subsystem-" ] + config.system.nixos.version;
}
