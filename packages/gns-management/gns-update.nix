{ all-packages
, garuda-lib
, self
, system
}:
let
  nixos = (garuda-lib.garudaSystem { inherit system; modules = [{ }]; }).config.system.build;
  version = builtins.toString garuda-lib.garuda-lib.version;
  executable = builtins.readFile ./gns-update.bash;
in
all-packages.writeShellApplication {
  name = "gns-update";
  runtimeInputs = with all-packages; [ util-linux btrfs-progs coreutils mktemp jq nixos.nixos-install nixos.nixos-rebuild nix ];

  text = builtins.replaceStrings [ "[[GNS_CURRENT_VERSION]]" "[[GNS_SELF]]" ] [ version (builtins.toString self) ] executable;
}
