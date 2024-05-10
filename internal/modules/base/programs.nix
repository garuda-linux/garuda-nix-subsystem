{ config
, garuda-lib
, lib
, pkgs
, ...
}:
with garuda-lib;
{
  options.garuda.excludes = gCreateExclusionOption "defaultpackages";
  config = {
    # Default applications
    environment.systemPackages = with pkgs; gExcludableArray config "defaultpackages" [
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
    boot.binfmt.registrations = lib.mkIf config.garuda.system.isGui (lib.genAttrs [ "appimage" "AppImage" ] (ext: {
      interpreter = "/run/current-system/sw/bin/appimage-run";
      magicOrExtension = ext;
      recognitionType = "extension";
    }));

    # Run unpatched linux binaries with nix-ld
    programs.nix-ld = {
      enable = gDefault config.garuda.system.isGui;
      libraries = with pkgs; [
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
        xorg.libX11
        zlib
      ];
    };

    # Easy launching of apps via "comma", contains command-not-found database
    programs = {
      nix-index-database.comma.enable = gDefault config.garuda.system.isGui;
      command-not-found.enable = gDefault false;
    };

    # Disabled by default, but very useful
    xdg.portal = {
      enable = gDefault config.garuda.system.isGui;
      xdgOpenUsePortal = gDefault config.garuda.system.isGui;
    };
  };
}
