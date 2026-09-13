{ ... }:
{
  imports = [ ./iso.nix ];

  garuda.mokka.enable = true;

  isoImage.edition = "mokka";
}
