{
  config,
  lib,
  pkgs,
  garuda-lib,
  ...
}:
with garuda-lib;
let
  greeter = config.services.displayManager.plasma-login-manager.enable or false;

  theme =
    if config.garuda.mokka.enable then
      {
        lookAndFeel = "Mokka";
        widgetStyle = "kvantum-dark";
        font = "Inter,10,-1,5,75,0,0,0,0,0,Bold";
        fixed = "Liberation Mono,10,-1,5,75,0,0,0,0,0,Bold";
        activeFont = "Inter,10,-1,5,75,0,0,0,0,0,Bold";
        icons = "Tela-circle-dracula-dark";
        cursor = "catppuccin-mocha-mauve-cursors";
        kvantum = "Mokka";
      }
    else if config.garuda.dr460nized.enable then
      {
        lookAndFeel = "Dr460nized";
        widgetStyle = "kvantum-dark";
        font = "Fira Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
        fixed = "FiraCode Nerd Font Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
        activeFont = "Fira Sans,10,-1,5,75,0,0,0,0,0,Bold";
        icons = "BeautyLine";
        cursor = "Sweet-cursors";
        kvantum = "Dr460nized";
      }
    else
      {
        lookAndFeel = "Catppuccin-Mocha-Mauve";
        widgetStyle = "Breeze";
        font = "Inter,10,-1,5,700,0,0,0,0,0,0,0,0,0,0,1,Bold";
        fixed = "JetBrainsMonoNL Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
        activeFont = "Inter,10,-1,5,800,0,0,0,0,0,0,0,0,0,0,1,ExtraBold";
        icons = "Tela-circle-catppuccin-dark";
        cursor = "catppuccin-mocha-mauve-cursors";
        kvantum = null;
      };

  seed = pkgs.runCommand "plasmalogin-seed" { } ''
    mkdir -p $out/.config
    cat > $out/.config/kdeglobals <<EOF
    [General]
    fixed=${theme.fixed}
    font=${theme.font}
    menuFont=${theme.font}
    smallestReadableFont=${theme.font}
    toolBarFont=${theme.font}

    [KDE]
    LookAndFeelPackage=${theme.lookAndFeel}
    ShowDeleteCommand=true
    SingleClick=true
    ${lib.optionalString (theme.widgetStyle != null) "widgetStyle=${theme.widgetStyle}"}
    ${lib.optionalString (theme.icons != null) "\n[Icons]\nTheme=${theme.icons}"}

    [WM]
    activeFont=${theme.activeFont}
    EOF
    ${lib.optionalString (theme.cursor != null) ''
      cat > $out/.config/kcminputrc <<EOF
      [Mouse]
      cursorTheme=${theme.cursor}
      EOF
    ''}
    ${lib.optionalString (theme.kvantum != null) ''
      mkdir -p $out/.config/Kvantum
      cat > $out/.config/Kvantum/kvantum.kvconfig <<EOF
      [General]
      theme=${theme.kvantum}
      EOF
    ''}
  '';
in
{
  config = lib.mkIf greeter {
    systemd.tmpfiles.settings."20-plasmalogin-theme" = {
      "/var/lib/plasmalogin/.config/kdeglobals"."C+" = {
        argument = "${seed}/.config/kdeglobals";
        user = "plasmalogin";
        group = "plasmalogin";
        mode = "0644";
      };
      "/var/lib/plasmalogin/.config/kcminputrc" = lib.mkIf (theme.cursor != null) {
        "C+" = {
          argument = "${seed}/.config/kcminputrc";
          user = "plasmalogin";
          group = "plasmalogin";
          mode = "0644";
        };
      };
      "/var/lib/plasmalogin/.config/Kvantum/kvantum.kvconfig" = lib.mkIf (theme.kvantum != null) {
        "C+" = {
          argument = "${seed}/.config/Kvantum/kvantum.kvconfig";
          user = "plasmalogin";
          group = "plasmalogin";
          mode = "0644";
        };
      };
    };
  };
}
