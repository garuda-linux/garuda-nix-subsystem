{ inputs, overlay, ... }: { config
                          , ...
                          }: {
  imports = [
    ./autologin.nix
    ./boot.nix
    ./create-home.nix
    ./gaming.nix
    ./garuda-update.nix
    ./hardware.nix
    ./home-manager/home-manager.nix
    ./locales.nix
    ./mount-garuda.nix
    ./networking.nix
    (import ./nix.nix { inherit overlay; })
    ./nix-manager.nix
    ./performance.nix
    # ./pkgs-overrides.nix
    ./programs.nix
    ./services.nix
    ./shells.nix
    ./sound.nix
    ./system_info.nix
    ./managed
  ];

  # Pass inputs via flake-inputs to the modules
  _module.args.flake-inputs = inputs;

  # Custom label for boot menu entries
  system.nixos.label = builtins.concatStringsSep "-" [ "garuda-nix-subsystem-" ] + config.system.nixos.version;
}
