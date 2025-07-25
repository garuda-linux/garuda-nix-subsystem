{ lib
, pkgs
, garuda-lib
, config
, ...
}:
let
  cfg = config.garuda.catppuccin;
  glib = garuda-lib;
in
lib.mkIf cfg.enable {
  environment.systemPackages = with pkgs; glib.gExcludableArray config "defaultpackages" [
    applet-window-title
    (catppuccin.override {
      accent = "mauve";
      variant = "mocha";
      themeList = [ "bat" "btop" "kvantum" ];
    })
    catppuccin-cursors.mochaMauve
    (catppuccin-kde.override {
      accents = [ "mauve" ];
      flavour = [ "mocha" ];
      winDecStyles = [ "classic" ];
    })
    (catppuccin-papirus-folders.override {
      accent = "mauve";
      flavor = "mocha";
    })
    ffmpegthumbnailer
    firedragon
    jamesdsp
    kdePackages.applet-window-buttons6
    kdePackages.kdegraphics-thumbnailers
    kdePackages.kimageformats
    kdePackages.kio-admin
    kdePackages.qtstyleplugin-kvantum
    kdePackages.sddm-kcm
    libinput-gestures
    plasma-plugin-blurredwallpaper
    resvg
    sshfs
    vlc
    xdg-desktop-portal
  ];

  xdg.mime.defaultApplications =
    let
      # Take from the respective mimetype files
      images = [
        "image/bmp"
        "image/gif"
        "image/jpeg"
        "image/jpg"
        "image/pjpeg"
        "image/png"
        "image/svg+xml"
        "image/svg+xml-compressed"
        "image/tiff"
        "image/vnd.wap.wbmp;image/x-icns"
        "image/x-bmp"
        "image/x-gray"
        "image/x-icb"
        "image/x-ico"
        "image/x-pcx"
        "image/x-png"
        "image/x-portable-anymap"
        "image/x-portable-bitmap"
        "image/x-portable-graymap"
        "image/x-portable-pixmap"
        "image/x-xbitmap"
        "image/x-xpixmap"
      ];
      urls = [
        "text/html"
        "x-scheme-handler/about"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/unknown"
      ];
      documents = [
        "application/illustrator"
        "application/oxps"
        "application/pdf"
        "application/postscript"
        "application/vnd.comicbook+zip"
        "application/vnd.comicbook-rar"
        "application/vnd.ms-xpsdocument"
        "application/x-bzdvi"
        "application/x-bzpdf"
        "application/x-bzpostscript"
        "application/x-cb7"
        "application/x-cbr"
        "application/x-cbt"
        "application/x-cbz"
        "application/x-dvi"
        "application/x-ext-cb7"
        "application/x-ext-cbr"
        "application/x-ext-cbt"
        "application/x-ext-cbz"
        "application/x-ext-djv"
        "application/x-ext-djvu"
        "application/x-ext-dvi"
        "application/x-ext-eps"
        "application/x-ext-pdf"
        "application/x-ext-ps"
        "application/x-gzdvi"
        "application/x-gzpdf"
        "application/x-gzpostscript"
        "application/x-xzpdf"
        "image/tiff"
        "image/vnd.djvu+multipage"
        "image/x-bzeps"
        "image/x-eps"
        "image/x-gzeps"
      ];
      audioVideo = [
        "application/mxf"
        "application/ogg"
        "application/sdp"
        "application/smil"
        "application/streamingmedia"
        "application/vnd.apple.mpegurl"
        "application/vnd.ms-asf"
        "application/vnd.rn-realmedia"
        "application/vnd.rn-realmedia-vbr"
        "application/x-cue"
        "application/x-extension-m4a"
        "application/x-extension-mp4"
        "application/x-matroska"
        "application/x-mpegurl"
        "application/x-ogg"
        "application/x-ogm"
        "application/x-ogm-audio"
        "application/x-ogm-video"
        "application/x-shorten"
        "application/x-smil"
        "application/x-streamingmedia"
        "audio/3gpp"
        "audio/3gpp2"
        "audio/AMR"
        "audio/aac"
        "audio/ac3"
        "audio/aiff"
        "audio/amr-wb"
        "audio/dv"
        "audio/eac3"
        "audio/flac"
        "audio/m3u"
        "audio/m4a"
        "audio/mp1"
        "audio/mp2"
        "audio/mp3"
        "audio/mp4"
        "audio/mpeg"
        "audio/mpeg2"
        "audio/mpeg3"
        "audio/mpegurl"
        "audio/mpg"
        "audio/musepack"
        "audio/ogg"
        "audio/opus"
        "audio/rn-mpeg"
        "audio/scpls"
        "audio/vnd.dolby.heaac.1"
        "audio/vnd.dolby.heaac.2"
        "audio/vnd.dts"
        "audio/vnd.dts.hd"
        "audio/vnd.rn-realaudio"
        "audio/vorbis"
        "audio/wav"
        "audio/webm"
        "audio/x-aac"
        "audio/x-adpcm"
        "audio/x-aiff"
        "audio/x-ape"
        "audio/x-m4a"
        "audio/x-matroska"
        "audio/x-mp1"
        "audio/x-mp2"
        "audio/x-mp3"
        "audio/x-mpegurl"
        "audio/x-mpg"
        "audio/x-ms-asf"
        "audio/x-ms-wma"
        "audio/x-musepack"
        "audio/x-pls"
        "audio/x-pn-au"
        "audio/x-pn-realaudio"
        "audio/x-pn-wav"
        "audio/x-pn-windows-pcm"
        "audio/x-realaudio"
        "audio/x-scpls"
        "audio/x-shorten"
        "audio/x-tta"
        "audio/x-vorbis"
        "audio/x-vorbis+ogg"
        "audio/x-wav"
        "audio/x-wavpack"
        "video/3gp"
        "video/3gpp"
        "video/3gpp2"
        "video/avi"
        "video/divx"
        "video/dv"
        "video/fli"
        "video/flv"
        "video/mkv"
        "video/mp2t"
        "video/mp4"
        "video/mp4v-es"
        "video/mpeg"
        "video/msvideo"
        "video/ogg"
        "video/quicktime"
        "video/vnd.divx"
        "video/vnd.mpegurl"
        "video/vnd.rn-realvideo"
        "video/webm"
        "video/x-avi"
        "video/x-flc"
        "video/x-flic"
        "video/x-flv"
        "video/x-m4v"
        "video/x-matroska"
        "video/x-mpeg2"
        "video/x-mpeg3"
        "video/x-ms-afs"
        "video/x-ms-asf"
        "video/x-ms-wmv"
        "video/x-ms-wmx"
        "video/x-ms-wvxvideo"
        "video/x-msvideo"
        "video/x-ogm"
        "video/x-ogm+ogg"
        "video/x-theora"
        "video/x-theora+ogg"
      ];
      archives = [
        "application/bzip2"
        "application/gzip"
        "application/vnd.android.package-archive"
        "application/vnd.debian.binary-package"
        "application/vnd.ms-cab-compressed"
        "application/x-7z-compressed"
        "application/x-7z-compressed-tar"
        "application/x-ace"
        "application/x-alz"
        "application/x-ar"
        "application/x-archive"
        "application/x-arj"
        "application/x-brotli"
        "application/x-bzip"
        "application/x-bzip-brotli-tar"
        "application/x-bzip-compressed-tar"
        "application/x-bzip1"
        "application/x-bzip1-compressed-tar"
        "application/x-cabinet"
        "application/x-cd-image"
        "application/x-chrome-extension"
        "application/x-compress"
        "application/x-compressed-tar"
        "application/x-cpio"
        "application/x-deb"
        "application/x-ear"
        "application/x-gtar"
        "application/x-gzip"
        "application/x-gzpostscript"
        "application/x-java-archive"
        "application/x-lha"
        "application/x-lhz"
        "application/x-lrzip"
        "application/x-lrzip-compressed-tar"
        "application/x-lz4"
        "application/x-lz4-compressed-tar"
        "application/x-lzip"
        "application/x-lzip-compressed-tar"
        "application/x-lzma"
        "application/x-lzma-compressed-tar"
        "application/x-lzop"
        "application/x-ms-dos-executable"
        "application/x-ms-wim"
        "application/x-rar"
        "application/x-rar-compressed"
        "application/x-rpm"
        "application/x-rzip"
        "application/x-rzip-compressed-tar"
        "application/x-source-rpm"
        "application/x-stuffit"
        "application/x-tar"
        "application/x-tarz"
        "application/x-tzo"
        "application/x-war"
        "application/x-xar"
        "application/x-xz"
        "application/x-xz-compressed-tar"
        "application/x-zip"
        "application/x-zip-compressed"
        "application/x-zoo"
        "application/x-zstd-compressed-tar"
        "application/zip"
        "application/zstd"
      ];
      code = [
        "application/x-shellscript"
        "text/english"
        "text/plain"
        "text/x-c"
        "text/x-c++"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-makefile"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
      ];
    in
    (lib.genAttrs code (_: [ "kate.desktop" ]))
    // (lib.genAttrs archives (_: [ "ark.desktop" ]))
    // (lib.genAttrs audioVideo (_: [ "vlc.desktop" ]))
    // (lib.genAttrs documents (_: [ "okular.desktop" ]))
    // (lib.genAttrs images (_: [ "gwenview.desktop" ]))
    // (lib.genAttrs urls (_: [ "firedragon.desktop" ]));
}
