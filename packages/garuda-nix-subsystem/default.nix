{
  all-packages,
  garuda-update,
}:
{
  cli = all-packages.callPackage ./cli.nix {
    inherit all-packages garuda-update;
  };
}
