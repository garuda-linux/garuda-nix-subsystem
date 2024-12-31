set -e

unset LD_PRELOAD LD_LIBRARY_PATH

function createOriginalConfiguration {
    if ! [ -f "$MNT_DIR/etc/nixos/flake.nix" ]; then
    cat > "$MNT_DIR/etc/nixos/flake.nix" << EOF
{
    description = "Garuda Linux Nix Subsystem Flake";

    inputs = {
    garuda.url = "gitlab:garuda-linux/garuda-nix-subsystem/stable";
    };

    outputs = { self, garuda }:
    let
        system = "x86_64-linux";
    in
    {
        nixosConfigurations.$HOSTNAME = garuda.lib.garudaSystem {
        inherit system;
        modules = [ ./configuration.nix ];
        };
    };
}
EOF
    fi
    if ! [ -f "$MNT_DIR/etc/nixos/configuration.nix" ]; then
    cat > "$MNT_DIR/etc/nixos/configuration.nix" <<- EOF
{ config, pkgs, lib, ... }:
with lib;
{
    imports = [
    ./hardware-configuration.nix
    ];
    # Do not remove these subsystem settings
    garuda.subsystem.enable = true;
    garuda.managed.config = ./garuda-managed.json;

    garuda.dr460nized.enable = true;

    # This should never be changed unless you know exactly what you are doing.
    # This has no impact on any package updates or OS version.
    system.stateVersion = "24.11";
}
EOF
    fi

    if ! [ -f "$MNT_DIR/etc/nixos/hardware-configuration.nix" ]; then
    nixos-generate-config --root "$MNT_DIR"
    fi

    if ! [ -f "$MNT_DIR/etc/nixos/garuda-managed.json" ]; then
    jq -n --arg installVersion "[[GNS_CURRENT_VERSION]]" --arg hostname "$HOSTNAME" '{"installVersion":$installVersion|tonumber, "version":$installVersion|tonumber, "hostname":$hostname, "v2": { "subsystem": true }}' > "$MNT_DIR/etc/nixos/garuda-managed.json"
    fi
}

if [[ $EUID -ne 0 ]]; then
    exit 1
fi

unset TMPDIR

BTRFS_UUID="$(findmnt -n -o UUID /)"
MNT_DIR="$(mktemp -d)"
HOSTNAME="$(cat /etc/hostname)"

mount "UUID=$BTRFS_UUID" "$MNT_DIR"
if ! [ -d "$MNT_DIR/@nix-subsystem" ]; then
    echo -e "\n\033[1;33m-->\033[1;34m Creating Garuda Nix Subsystem subvolume\033[0m\n"
    btrfs subvolume create "$MNT_DIR"/@nix-subsystem
fi
umount "$MNT_DIR"
rmdir "$MNT_DIR"

echo -e "\033[1;33m-->\033[1;34m Mounting Garuda Nix Subsystem subvolumes\033[0m"
MNT_DIR=$(mktemp -d)
mount -o subvol=@nix-subsystem "UUID=$BTRFS_UUID" "$MNT_DIR"
mkdir -p "$MNT_DIR/nix"
mount -o subvol=@nix "UUID=$BTRFS_UUID" "$MNT_DIR/nix"

echo -e "\n\033[1;33m-->\033[1;34m Configuring Garuda Nix Subsystem\033[0m\n"

mkdir -p "$MNT_DIR"/etc/nixos

if [ -f "$MNT_DIR/etc/nixos/garuda-managed.json" ]; then
    echo -e "\033[1;31mError: Garuda Nix Subsystem is already installed on this system. ❌\033[0m";
    exit 1
fi

createOriginalConfiguration

# Delegate!
GNS_MNT_DIR="$MNT_DIR" GNS_BTRFS_UUID="$BTRFS_UUID" GNS_FROM_HOST=true GNS_INSTALLING=true gns-update