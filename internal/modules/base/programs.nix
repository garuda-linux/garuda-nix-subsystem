{
  config,
  garuda-lib,
  lib,
  pkgs,
  ...
}:
with garuda-lib;
{
  options.garuda.excludes =
    (gCreateExclusionOption "defaultpackages") // (gCreateExclusionOption "nixldlibraries");
  config = {
    # Default applications
    environment.systemPackages =
      with pkgs;
      gExcludableArray config "defaultpackages" [
        bat
        curl
        eza
        fastfetch
        fishPlugins.done
        fishPlugins.autopair
        fishPlugins.puffer
        git
        htop
        killall
        micro
        nvd
        rsync
        screen
        tldr
        ugrep
        wget
      ];

    # We want to be insulted on wrong passwords
    security.sudo = {
      extraConfig = ''
        Defaults pwfeedback
        Defaults insults
      '';
    };

    # Run Appimages with appimage-run
    boot.binfmt.registrations = lib.mkIf config.garuda.system.isGui (
      lib.genAttrs [ "appimage" "AppImage" ] (ext: {
        interpreter = "/run/current-system/sw/bin/appimage-run";
        magicOrExtension = ext;
        recognitionType = "extension";
      })
    );

    # Run unpatched linux binaries with nix-ld
    programs.nix-ld = {
      enable = gDefault config.garuda.system.isGui;
      libraries =
        with pkgs;
        gExcludableArray config "nixldlibraries" [
          SDL2
          curl
          freetype
          gdk-pixbuf
          glib
          glibc
          icu
          libglvnd
          libnotify
          libsecret
          libunwind
          libuuid
          openssl
          stdenv.cc.cc
          util-linux
          vulkan-loader
          libx11
          zlib
        ];
    };

    # https://discourse.nixos.org/t/psa-use-nixos-org-tarballs-for-your-flake-inputs/79950
    programs.command-not-found.enable = gDefault config.garuda.system.isGui;

    # Disabled by default, but very useful
    xdg.portal = {
      enable = gDefault config.garuda.system.isGui;
      xdgOpenUsePortal = gDefault config.garuda.system.isGui;
    };
  };
}
