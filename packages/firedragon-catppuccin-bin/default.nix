{ callPackage }: callPackage ../firedragon-bin/generic.nix {
  shortName = "firedragon-catppuccin-bin";
  description = "Floorp fork with custom branding and opinionated defaults, Catppuccin variant";
  versionFile = ./version.json;
}
