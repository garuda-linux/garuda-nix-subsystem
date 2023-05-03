{ lib
, pkgs
, ...
}: {
  # Run appimages with appimage-run
  boot.binfmt.registrations = lib.genAttrs [ "appimage" "AppImage" ] (ext: {
    interpreter = "/run/current-system/sw/bin/appimage-run";
    magicOrExtension = ext;
    recognitionType = "extension";
  });

  # Run unpatched linux binaries with nix-ld
  programs.nix-ld = {
    enable = true;
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
}
