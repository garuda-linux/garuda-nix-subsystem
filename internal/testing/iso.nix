{
  pkgs,
  lib,
  flake-inputs,
  ...
}:
{
  imports = [
    # NixOS graphical Calamares installer ISO. The overlay in this flake
    # swaps calamares-nixos-extensions for the Garuda variant, so no need to override the module here.
    "${flake-inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix"
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.xserver.enable = lib.mkForce false;

  environment.defaultPackages = lib.mkForce [
    pkgs.rsync
    pkgs.vim
    pkgs.nano
  ];

  # Hardware probing for the installer
  environment.systemPackages = [
    pkgs.nixos-facter
  ];

  systemd.oomd.enable = lib.mkForce false;
  zramSwap.enable = true;

  services.qemuGuest.enable = lib.mkForce true;
  virtualisation.virtualbox.guest.enable = lib.mkForce true;

  services.displayManager.autoLogin = {
    enable = true;
    user = lib.mkForce "garuda";
  };

  users.users.garuda = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
    initialHashedPassword = "";
  };
  users.users.nixos.enable = lib.mkForce false;

  services.getty.autologinUser = lib.mkForce "garuda";
  services.getty.helpLine = lib.mkForce ''
    The "garuda" and "root" accounts have empty passwords.

    To log in over ssh you must set a password for either "garuda" or "root"
    with `passwd` (prefix with `sudo` for "root"), or add your public key to
    /home/garuda/.ssh/authorized_keys or /root/.ssh/authorized_keys.

    To set up a wireless connection, run `nmtui`.
  '';
  nix.settings.trusted-users = lib.mkForce [
    "root"
    "garuda"
  ];

  home-manager.users.garuda.programs.vicinae.systemd.enable = lib.mkForce false;

  # Upstream launches calamares via pkexec, which strips the user env,
  # while sudo -E preserves it. This makes the desktop theme available to calamares.
  environment.etc."xdg/autostart/calamares.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Version=1.0
    Name=Install System
    GenericName=System Installer
    TryExec=calamares
    Exec=sh -c "sudo -E calamares"
    Comment=Calamares — System Installer
    Icon=calamares
    Terminal=false
    StartupNotify=true
    Categories=Qt;System;
    X-AppStream-Ignore=true
    X-KDE-autostart-phase=2
  '';
}
