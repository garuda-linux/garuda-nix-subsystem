# The smallest and KISSer continuos-deploy I was able to create.
{ all-packages
, garuda-lib
, system
}:
let
  nixos = (garuda-lib.garudaSystem { inherit system; modules = [{ }]; }).config.system.build;
  version = builtins.toString garuda-lib.garuda-lib.version;
  executable = builtins.readFile ./installer.bash;
in
all-packages.writeShellApplication {
  name = "gns-install";
  runtimeInputs = with all-packages; [ util-linux btrfs-progs coreutils mktemp jq nixos.nixos-generate-config nix ];

  text = builtins.replaceStrings [ "[[GNS_CURRENT_VERSION]]" ] [ version ] executable;
}
