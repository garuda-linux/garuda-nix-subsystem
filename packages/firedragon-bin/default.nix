{ callPackage }: callPackage ./generic.nix {
  shortName = "firedragon-bin";
  description = "Floorp fork with custom branding and opinionated defaults";
  versionFile = ./version.json;
}
