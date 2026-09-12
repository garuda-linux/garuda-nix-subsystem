{
  terminalEntries,
  startcenterIcon,
  writerIcon,
}:
{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  appdir = ".local/share/applications";
  pkgnames =
    (lib.forEach config.home.packages (x: lib.getName x))
    ++ lib.forEach osConfig.environment.systemPackages (x: lib.getName x);
  findPkg =
    name:
    let
      home = lib.findFirst (x: (lib.getName x) == name) null config.home.packages;
      system = lib.findFirst (x: (lib.getName x) == name) null osConfig.environment.systemPackages;
    in
    if home != null then
      home
    else if system != null then
      system
    else
      builtins.throw ("garuda-nix-subsystem: package not found: " + name);
  libreoffice-qt = findPkg "libreoffice";

  launcher = name: item: {
    "${appdir}/${name}.desktop".source = "${item}/share/applications/${name}.desktop";
  };

  soffice = sub: "${libreoffice-qt}/bin/soffice ${sub}";
in
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
  };

  programs.vicinae = {
    enable = lib.mkDefault true;
    systemd.enable = lib.mkDefault true;
  };

  home.file = lib.mkMerge (
    [
      {
        ".config/plasma-workspace/env/10-env.sh".text = ''
          #!/run/current-system/sw/bin/bash
          export ENV_CLEANED=1
          QT_PLUGIN_PATH_MOD="$(echo $QT_PLUGIN_PATH | tr ':' '\n' | grep "/" | awk '!x[$0]++' | head -c -1 | tr '\n' ':')"
          XDG_DATA_DIRS_MOD="$(echo $XDG_DATA_DIRS | tr ':' '\n' | grep "/" | awk '!x[$0]++' | head -c -1 | tr '\n' ':')"
          XDG_CONFIG_DIRS_MOD="$(echo $XDG_CONFIG_DIRS | tr ':' '\n' | grep "/" | awk '!x[$0]++' | head -c -1 | tr '\n' ':')"
          export QT_PLUGIN_PATH=$QT_PLUGIN_PATH_MOD
          export XDG_DATA_DIRS=$XDG_DATA_DIRS_MOD
          export XDG_CONFIG_DIRS=$XDG_CONFIG_DIRS_MOD
        '';
      }
    ]
    ++ lib.optional (builtins.elem "btop" pkgnames) (
      launcher "btop" (
        pkgs.makeDesktopItem {
          name = "btop";
          desktopName = "btop++";
          genericName = "System Monitor";
          comment = "Resource monitor that shows usage and stats for processor, memory, disks, network and processes";
          exec = "${findPkg "btop"}/bin/btop";
          icon = "org.kde.resourcesMonitor";
          categories = [
            "System"
            "Monitor"
            "ConsoleOnly"
          ];
          keywords = [
            "system"
            "process"
            "task"
          ];
          terminal = true;
          startupNotify = true;
        }
      )
    )
    ++ lib.optionals terminalEntries [
      (launcher "fish" (
        pkgs.makeDesktopItem {
          name = "fish";
          desktopName = "Fish";
          comment = "The user-friendly command line shell";
          exec = "${findPkg "fish"}/bin/fish";
          icon = "fish";
          categories = [
            "ConsoleOnly"
            "System"
          ];
          terminal = true;
          startupNotify = true;
        }
      ))
      (launcher "micro" (
        pkgs.makeDesktopItem {
          name = "micro";
          desktopName = "Micro";
          genericName = "Text Editor";
          comment = "Edit text files in a terminal";
          exec = "${findPkg "micro"}/bin/micro %F";
          icon = "text-editor";
          categories = [
            "Utility"
            "TextEditor"
            "Development"
          ];
          keywords = [
            "text"
            "editor"
            "syntax"
            "terminal"
          ];
          mimeTypes = [
            "text/plain"
            "text/x-chdr"
            "text/x-csrc"
            "text/x-c++hdr"
            "text/x-c++src"
            "text/x-java"
            "text/x-dsrc"
            "text/x-pascal"
            "text/x-perl"
            "text/x-python"
            "application/x-php"
            "application/x-httpd-php3"
            "application/x-httpd-php4"
            "application/x-httpd-php5"
            "application/xml"
            "text/html"
            "text/css"
            "text/x-sql"
            "text/x-diff"
          ];
          terminal = true;
          startupNotify = false;
        }
      ))
    ]
    ++ lib.optionals (builtins.elem "libreoffice" pkgnames) [
      (launcher "startcenter" (
        pkgs.makeDesktopItem {
          name = "startcenter";
          desktopName = "LibreOffice";
          genericName = "Office";
          comment = "Launch applications to create text documents, spreadsheets, presentations, drawings, formulas, and databases, or open recently used documents.";
          exec = "${libreoffice-qt}/bin/soffice %U";
          icon = startcenterIcon;
          categories = [
            "Office"
            "X-Red-Hat-Base"
            "X-SuSE-Core-Office"
          ];
          mimeTypes = [
            "application/vnd.openofficeorg.extension"
            "x-scheme-handler/vnd.libreoffice.cmis"
            "x-scheme-handler/vnd.sun.star.webdav"
            "x-scheme-handler/vnd.sun.star.webdavs"
            "x-scheme-handler/vnd.libreoffice.command"
            "x-scheme-handler/ms-word"
            "x-scheme-handler/ms-powerpoint"
            "x-scheme-handler/ms-excel"
            "x-scheme-handler/ms-visio"
            "x-scheme-handler/ms-access"
          ];
          startupNotify = true;
          startupWMClass = "libreoffice-startcenter";
          actions = {
            Writer = {
              name = "Writer";
              exec = soffice "--writer";
            };
            Calc = {
              name = "Calc";
              exec = soffice "--calc";
            };
            Impress = {
              name = "Impress";
              exec = soffice "--impress";
            };
            Draw = {
              name = "Draw";
              exec = soffice "--draw";
            };
            Base = {
              name = "Base";
              exec = soffice "--base";
            };
            Math = {
              name = "Math";
              exec = soffice "--math";
            };
          };
          extraConfig = {
            "GenericName[en_GB]" = "Office";
            "X-GIO-NoFuse" = "true";
            "X-KDE-Protocols" = "file,http,ftp,webdav,webdavs";
            "X-KDE-SubstituteUID" = "false";
          };
        }
      ))
      (launcher "math" (
        pkgs.makeDesktopItem {
          name = "math";
          desktopName = "LibreOffice Math";
          genericName = "Formula Editor";
          comment = "Create and edit scientific formulas and equations.";
          exec = "${libreoffice-qt}/bin/soffice --math %U";
          icon = "org.libreoffice.LibreOffice.math";
          categories = [
            "Office"
            "Education"
            "Science"
            "Math"
            "X-Red-Hat-Base"
          ];
          keywords = [
            "Equation"
            "OpenDocument Formula"
            "Formula"
            "of"
            "MathML"
          ];
          mimeTypes = [
            "application/vnd.oasis.opendocument.formula"
            "application/vnd.sun.xml.math"
            "application/vnd.oasis.opendocument.formula-template"
            "text/mathml"
            "application/mathml+xml"
          ];
          startupNotify = true;
          startupWMClass = "libreoffice-math";
          actions.NewDocument = {
            name = "New Formula";
            exec = soffice "--math";
            icon = "document-new";
          };
          extraConfig = {
            "GenericName[en_GB]" = "Formula Editor";
            "InitialPreference" = "5";
            "X-GIO-NoFuse" = "true";
            "X-KDE-Protocols" = "file,http,ftp,webdav,webdavs";
            "X-KDE-SubstituteUID" = "false";
          };
        }
      ))
      (launcher "impress" (
        pkgs.makeDesktopItem {
          name = "impress";
          desktopName = "LibreOffice Impress";
          genericName = "Presentation";
          comment = "Create and edit presentations for slideshows, meetings and Web pages.";
          exec = "${libreoffice-qt}/bin/soffice --impress %U";
          icon = "org.libreoffice.LibreOffice.impress";
          categories = [
            "Office"
            "Presentation"
            "X-Red-Hat-Base"
          ];
          keywords = [
            "Slideshow"
            "Slides"
            "OpenDocument Presentation"
            "Microsoft PowerPoint"
            "Microsoft Works"
            "OpenOffice Impress"
            "odp"
            "ppt"
            "pptx"
          ];
          mimeTypes = [
            "application/vnd.oasis.opendocument.presentation"
            "application/vnd.oasis.opendocument.presentation-template"
            "application/vnd.sun.xml.impress"
            "application/vnd.sun.xml.impress.template"
            "application/mspowerpoint"
            "application/vnd.ms-powerpoint"
            "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            "application/vnd.ms-powerpoint.presentation.macroEnabled.12"
            "application/vnd.openxmlformats-officedocument.presentationml.template"
            "application/vnd.ms-powerpoint.template.macroEnabled.12"
            "application/vnd.openxmlformats-officedocument.presentationml.slide"
            "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
            "application/vnd.ms-powerpoint.slideshow.macroEnabled.12"
            "application/vnd.oasis.opendocument.presentation-flat-xml"
            "application/x-iwork-keynote-sffkey"
            "application/vnd.apple.keynote"
          ];
          startupNotify = true;
          startupWMClass = "libreoffice-impress";
          actions.NewDocument = {
            name = "New Presentation";
            exec = soffice "--impress";
            icon = "document-new";
          };
          extraConfig = {
            "GenericName[en_GB]" = "Presentation";
            "InitialPreference" = "5";
            "X-GIO-NoFuse" = "true";
            "X-KDE-Protocols" = "file,http,ftp,webdav,webdavs";
            "X-KDE-SubstituteUID" = "false";
          };
        }
      ))
      (launcher "draw" (
        pkgs.makeDesktopItem {
          name = "draw";
          desktopName = "LibreOffice Draw";
          genericName = "Drawing Program";
          comment = "Create and edit drawings, flow charts and logos.";
          exec = "${libreoffice-qt}/bin/soffice --draw %U";
          icon = "org.libreoffice.LibreOffice.draw";
          categories = [
            "Office"
            "FlowChart"
            "Graphics"
            "2DGraphics"
            "VectorGraphics"
            "X-Red-Hat-Base"
          ];
          keywords = [
            "Vector"
            "Schema"
            "Diagram"
            "Layout"
            "OpenDocument Graphics"
            "Microsoft Publisher"
            "Microsoft Visio"
            "Corel Draw"
            "cdr"
            "odg"
            "svg"
            "pdf"
            "vsd"
          ];
          mimeTypes = [
            "application/vnd.oasis.opendocument.graphics"
            "application/vnd.oasis.opendocument.graphics-flat-xml"
            "application/vnd.oasis.opendocument.graphics-template"
            "application/vnd.sun.xml.draw"
            "application/vnd.sun.xml.draw.template"
            "application/vnd.visio"
            "application/x-wpg"
            "application/vnd.corel-draw"
            "application/vnd.ms-publisher"
            "image/x-freehand"
            "application/clarisworks"
            "application/x-pagemaker"
            "application/pdf"
            "application/x-stardraw"
            "image/x-emf"
            "image/x-wmf"
          ];
          startupNotify = true;
          startupWMClass = "libreoffice-draw";
          actions.NewDocument = {
            name = "New Drawing";
            exec = soffice "--draw";
            icon = "document-new";
          };
          extraConfig = {
            "GenericName[en_GB]" = "Drawing Program";
            "InitialPreference" = "5";
            "X-GIO-NoFuse" = "true";
            "X-KDE-Protocols" = "file,http,ftp,webdav,webdavs";
            "X-KDE-SubstituteUID" = "false";
          };
        }
      ))
      (launcher "calc" (
        pkgs.makeDesktopItem {
          name = "calc";
          desktopName = "LibreOffice Calc";
          genericName = "Spreadsheet";
          comment = "Perform calculations, analyze information and manage lists in spreadsheets.";
          exec = "${libreoffice-qt}/bin/soffice --calc %U";
          icon = "org.libreoffice.LibreOffice.calc";
          categories = [
            "Office"
            "Spreadsheet"
            "X-Red-Hat-Base"
          ];
          keywords = [
            "Accounting"
            "Stats"
            "OpenDocument Spreadsheet"
            "Chart"
            "Microsoft Excel"
            "Microsoft Works"
            "OpenOffice Calc"
            "ods"
            "xls"
            "xlsx"
          ];
          mimeTypes = [
            "application/vnd.oasis.opendocument.spreadsheet"
            "application/vnd.oasis.opendocument.spreadsheet-template"
            "application/vnd.sun.xml.calc"
            "application/vnd.sun.xml.calc.template"
            "application/msexcel"
            "application/vnd.ms-excel"
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            "application/vnd.ms-excel.sheet.macroEnabled.12"
            "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
            "application/vnd.ms-excel.template.macroEnabled.12"
            "application/vnd.ms-excel.sheet.binary.macroEnabled.12"
            "text/csv"
            "application/x-dbf"
            "text/spreadsheet"
            "application/csv"
            "application/excel"
            "application/tab-separated-values"
            "text/tab-separated-values"
            "text/x-comma-separated-values"
            "text/x-csv"
            "application/vnd.oasis.opendocument.spreadsheet-flat-xml"
            "application/vnd.ms-works"
            "application/clarisworks"
            "application/x-iwork-numbers-sffnumbers"
            "application/vnd.apple.numbers"
            "application/x-starcalc"
          ];
          startupNotify = true;
          startupWMClass = "libreoffice-calc";
          actions.NewDocument = {
            name = "New Spreadsheet";
            exec = soffice "--calc";
            icon = "document-new";
          };
          extraConfig = {
            "GenericName[en_GB]" = "Spreadsheet";
            "InitialPreference" = "5";
            "X-GIO-NoFuse" = "true";
            "X-KDE-Protocols" = "file,http,ftp,webdav,webdavs";
            "X-KDE-SubstituteUID" = "false";
          };
        }
      ))
      (launcher "base" (
        pkgs.makeDesktopItem {
          name = "base";
          desktopName = "LibreOffice Base";
          genericName = "Database Development";
          comment = "Manage databases, create queries and reports to track and manage your information.";
          exec = "${libreoffice-qt}/bin/soffice --base %U";
          icon = "org.libreoffice.LibreOffice.base";
          categories = [
            "Office"
            "Database"
            "X-Red-Hat-Base"
          ];
          keywords = [
            "Data"
            "SQL"
          ];
          mimeTypes = [
            "application/vnd.oasis.opendocument.base"
            "application/vnd.sun.xml.base"
          ];
          startupNotify = true;
          startupWMClass = "libreoffice-base";
          actions.NewDocument = {
            name = "New Database";
            exec = soffice "--base";
            icon = "document-new";
          };
          extraConfig = {
            "GenericName[en_GB]" = "Database Development";
            "InitialPreference" = "5";
            "X-GIO-NoFuse" = "true";
            "X-KDE-Protocols" = "file,http,ftp,webdav,webdavs";
            "X-KDE-SubstituteUID" = "false";
          };
        }
      ))
      (launcher "writer" (
        pkgs.makeDesktopItem {
          name = "writer";
          desktopName = "LibreOffice Writer";
          genericName = "Word Processor";
          comment = "Create and edit text and graphics in letters, reports, documents and Web pages.";
          exec = "${libreoffice-qt}/bin/soffice --writer %U";
          icon = writerIcon;
          categories = [
            "Office"
            "WordProcessor"
            "X-Red-Hat-Base"
          ];
          keywords = [
            "Text"
            "Letter"
            "Fax"
            "Document"
            "OpenDocument Text"
            "Microsoft Word"
            "Microsoft Works"
            "Lotus WordPro"
            "OpenOffice Writer"
            "CV"
            "odt"
            "doc"
            "docx"
            "rtf"
          ];
          mimeTypes = [
            "application/vnd.oasis.opendocument.text"
            "application/vnd.oasis.opendocument.text-template"
            "application/vnd.oasis.opendocument.text-web"
            "application/vnd.oasis.opendocument.text-master"
            "application/vnd.oasis.opendocument.text-master-template"
            "application/vnd.sun.xml.writer"
            "application/vnd.sun.xml.writer.template"
            "application/vnd.sun.xml.writer.global"
            "application/msword"
            "application/vnd.ms-word"
            "application/x-doc"
            "application/x-hwp"
            "application/rtf"
            "text/rtf"
            "application/vnd.wordperfect"
            "application/wordperfect"
            "application/vnd.lotus-wordpro"
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "application/vnd.ms-word.document.macroEnabled.12"
            "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
            "application/vnd.ms-word.template.macroEnabled.12"
            "application/vnd.ms-works"
            "application/vnd.stardivision.writer-global"
            "application/x-extension-txt"
            "application/x-t602"
            "text/plain"
            "application/vnd.oasis.opendocument.text-flat-xml"
            "application/x-fictionbook+xml"
            "application/macwriteii"
            "application/x-aportisdoc"
            "application/prs.plucker"
            "application/vnd.palm"
            "application/clarisworks"
            "application/x-sony-bbeb"
            "application/x-abiword"
            "application/x-iwork-pages-sffpages"
            "application/vnd.apple.pages"
            "application/x-mswrite"
            "application/x-starwriter"
          ];
          startupNotify = true;
          startupWMClass = "libreoffice-writer";
          actions.NewDocument = {
            name = "New Document";
            exec = soffice "--writer";
            icon = "document-new";
          };
          extraConfig = {
            "GenericName[en_GB]" = "Word Processor";
            "InitialPreference" = "5";
            "X-GIO-NoFuse" = "true";
            "X-KDE-Protocols" = "file,http,ftp,webdav,webdavs";
            "X-KDE-SubstituteUID" = "false";
          };
        }
      ))
    ]
  );
}
