{
  all-packages,
  garuda-lib,
  garuda-installer-lib,
  system,
  self,
}:
{
  cli = all-packages.callPackage ./cli.nix {
    inherit
      garuda-lib
      garuda-installer-lib
      system
      self
      ;
    inherit (all-packages) gns-update;
  };
}
