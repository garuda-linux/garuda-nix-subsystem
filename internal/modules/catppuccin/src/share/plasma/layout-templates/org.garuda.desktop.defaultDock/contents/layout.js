var plasma = getApiVersion(1);

// Create bottom panel (Dock) //

const dock = new Panel();

// Basic Dock Geometry
dock.alignment = "center";
dock.height = Math.round(gridUnit * 3.8);
dock.hiding = "dodgewindows";
dock.lengthMode = "fit";
dock.location = "bottom";

// Icons-Only Task Manager
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("fill", false);
tasks.writeConfig("iconSpacing", 2);
tasks.writeConfig(
  "launchers",
  "applications:garuda-welcome.desktop,applications:org.kde.konsole.desktop,preferred://browser,preferred://filemanager,applications:org.kde.plasma-systemmonitor.desktop,applications:snapper-tools.desktop,applications:systemsettings.desktop,applications:octopi.desktop",
);
tasks.writeConfig("maxStripes", 1);
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("showOnlyCurrentScreen", false);

// End of Dock creation //
