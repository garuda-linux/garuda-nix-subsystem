{
  all-packages,
  gns-update,
}:
{
  cli = all-packages.callPackage ./cli.nix {
    inherit all-packages gns-update;
  };
}
