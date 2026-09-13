{ ... }:
{
  imports = [ ./iso.nix ];

  garuda.dr460nized.enable = true;

  isoImage.edition = "dr460nized";
}
