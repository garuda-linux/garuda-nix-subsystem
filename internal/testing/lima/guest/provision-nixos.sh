#!/usr/bin/env bash
# Turns the plain nixos-lima guest into an old Garuda Nix install.
# Usage (as root): provision-nixos.sh flake|managed
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

kind=${1:?usage: provision-nixos.sh flake|managed}
system="$(uname -m)-linux"

case "$kind" in
flake) host=garuda-lima ;;
managed) host=garuda-lima-nix ;;
*)
  echo "unknown kind: $kind" >&2
  exit 1
  ;;
esac

# The extra Lima disk stands in for the btrfs filesystem of the Garuda host,
# with the @home subvolume that the subsystem's shared home mounts.
home_disk() {
  local by_id=/dev/disk/by-id/virtio-lima-gns-managed-home root_disk

  if [ -e "$by_id" ]; then
    readlink -f "$by_id"
    return
  fi

  root_disk=$(lsblk -no PKNAME "$(findmnt -n -o SOURCE /)")
  lsblk -dnpo NAME,TYPE | awk '$2 == "disk" { print $1 }' | grep -vx "/dev/$root_disk" | head -n 1
}

setup_home_disk() {
  local dev mnt user=garuda uid=1500
  dev=$(home_disk)

  if [ -z "$dev" ]; then
    echo "The extra disk for @home is missing." >&2
    exit 1
  fi

  step "Formatting $dev as the host btrfs with @home"
  "${NIX[@]}" shell nixpkgs#btrfs-progs -c \
    mkfs.btrfs -q -f -L garuda-host "$dev"
  udevadm settle

  mnt=$(mktemp -d)
  mount "$dev" "$mnt"

  "${NIX[@]}" shell nixpkgs#btrfs-progs -c \
    btrfs subvolume create "$mnt/@home"

  # The host home of the imported user, with the directories the shared home binds
  mkdir -p "$mnt/@home/$user"/{.config,.local,.cache}
  chown -R "$uid:100" "$mnt/@home/$user"

  umount "$mnt"
  rmdir "$mnt"

  # The NixOS home of the imported user, bound over the host home on boot
  mkdir -p "/home/$user"/{.config,.local,.cache}
  chown -R "$uid:100" "/home/$user"
}

step "Writing /etc/nixos ($kind)"
if [ -d /etc/nixos ] && [ ! -d /etc/nixos.lima ]; then
  mv /etc/nixos /etc/nixos.lima
fi

rm -rf /etc/nixos
mkdir -p /etc/nixos
cp "$HARNESS/lima.nix" "$HARNESS/$kind/"* /etc/nixos/
chmod -R u+w /etc/nixos

sed -i -e "s|@GARUDA_URL@|$INSTALL_GARUDA_URL|" -e "s|@SYSTEM@|$system|" /etc/nixos/flake.nix

if [ "$kind" = managed ]; then
  setup_home_disk
  sed -i "s|@BTRFS_UUID@|$(blkid -s UUID -o value "$(home_disk)")|" /etc/nixos/garuda-managed.json
fi

git init -q /etc/nixos
git -C /etc/nixos add -A
commit_all /etc/nixos "Initial Garuda Nix configuration"

step "Installing Garuda Nix (this takes a while)"
nixos-rebuild switch --flake "/etc/nixos#$host" \
  --option experimental-features "nix-command flakes" \
  --option accept-flake-config true

step "Switching flake.nix to the old URL form"
sed -i "s|$INSTALL_GARUDA_URL|$OLD_GARUDA_URL|" /etc/nixos/flake.nix
commit_all /etc/nixos "Old garuda input URL"

step "Provisioned: $(generation) generation(s), flake.nix uses $OLD_GARUDA_URL"
