set -e

unset LD_PRELOAD LD_LIBRARY_PATH

FORCE=false
if [[ ${GNS_FORCE:-false} == "true" ]]; then FORCE=true; fi
ARGS=()
for arg in "$@"; do
  case "$arg" in
  --force | -f | --reinstall) FORCE=true ;;
  *) ARGS+=("$arg") ;;
  esac
done

if [ -n "${ARGS[0]:-}" ]; then
  EDITION="${ARGS[0]}"
elif [ -n "${GNS_EDITION:-}" ]; then
  EDITION="$GNS_EDITION"
elif [ -t 0 ]; then
  echo "Select edition:"
  PS3="Edition [1-2]: "
  select EDITION in dr460nized mokka; do
    case "$EDITION" in
    dr460nized | mokka) break ;;
    *) echo "Pick 1 for dr460nized or 2 for mokka." ;;
    esac
  done
else
  EDITION="dr460nized"
fi
case "$EDITION" in
dr460nized | mokka) ;;
*)
  echo -e "\033[1;31mError: Unknown edition '$EDITION'. Choose dr460nized or mokka. ❌\033[0m" >&2
  exit 1
  ;;
esac

function createOriginalConfiguration {
  if ! [ -f "$MNT_DIR/etc/nixos/flake.nix" ]; then
    cat >"$MNT_DIR/etc/nixos/flake.nix" <<EOF
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
    cat >"$MNT_DIR/etc/nixos/configuration.nix" <<-EOF
{ config, pkgs, lib, ... }:
with lib;
{
    imports = [
    ./hardware-configuration.nix
    ];
    # Do not remove these subsystem settings
    garuda.subsystem.enable = true;
    garuda.managed.config = ./garuda-managed.json;

    garuda.${EDITION}.enable = true;

    # This should never be changed unless you know exactly what you are doing.
    # This has no impact on any package updates or OS version.
    system.stateVersion = "26.05";
}
EOF
  fi

  if ! [ -f "$MNT_DIR/etc/nixos/hardware-configuration.nix" ]; then
    nixos-generate-config --root "$MNT_DIR"
  fi

  if ! [ -f "$MNT_DIR/etc/nixos/garuda-managed.json" ]; then
    jq -n --arg installVersion "[[GNS_CURRENT_VERSION]]" --arg hostname "$HOSTNAME" '{"installVersion":$installVersion|tonumber, "version":$installVersion|tonumber, "hostname":$hostname, "v2": { "subsystem": true }}' >"$MNT_DIR/etc/nixos/garuda-managed.json"
  fi
}

if [[ $EUID -ne 0 ]]; then
  exit 1
fi

unset TMPDIR

mkdir -p /run/gns

BTRFS_UUID="$(findmnt -n -o UUID /)"
MNT_DIR="$(TMPDIR=/run/gns mktemp -d)"
HOSTNAME="$(cat /etc/hostname)"

mount "UUID=$BTRFS_UUID" "$MNT_DIR"
if ! [ -d "$MNT_DIR/@nix-subsystem" ]; then
  echo -e "\n\033[1;33m-->\033[1;34m Creating Garuda Nix Subsystem subvolume\033[0m\n"
  btrfs subvolume create "$MNT_DIR"/@nix-subsystem
fi
umount "$MNT_DIR"
rmdir "$MNT_DIR"

echo -e "\033[1;33m-->\033[1;34m Mounting Garuda Nix Subsystem subvolumes\033[0m"
MNT_DIR=$(TMPDIR=/run/gns mktemp -d)

cleanup_install_mounts() {
  umount "$MNT_DIR/nix" 2>/dev/null || true
  umount "$MNT_DIR" 2>/dev/null || true
}
trap cleanup_install_mounts EXIT

mount -o subvol=@nix-subsystem "UUID=$BTRFS_UUID" "$MNT_DIR"
mkdir -p "$MNT_DIR/nix"
mount -o subvol=@nix "UUID=$BTRFS_UUID" "$MNT_DIR/nix"

echo -e "\n\033[1;33m-->\033[1;34m Configuring Garuda Nix Subsystem\033[0m\n"

mkdir -p "$MNT_DIR"/etc/nixos

if [ -f "$MNT_DIR/etc/nixos/garuda-managed.json" ]; then
  if [ -e "$MNT_DIR/nix/var/nix/profiles/system" ] || [ -e "$MNT_DIR/boot/grub/grub.cfg" ]; then
    if $FORCE; then
      echo -e "\033[1;33m-->\033[1;34m Forcing reinstall over existing installation\033[0m"
    else
      echo -e "\033[1;31mError: Garuda Nix Subsystem is already installed on this system. Pass --force to reinstall. ❌\033[0m"
      exit 1
    fi
  else
    echo -e "\033[1;33m-->\033[1;34m Previous incomplete install detected, resuming\033[0m"
  fi
fi

createOriginalConfiguration

# Delegate!
GNS_MNT_DIR="$MNT_DIR" GNS_BTRFS_UUID="$BTRFS_UUID" GNS_FROM_HOST=true GNS_INSTALLING=true gns-update
