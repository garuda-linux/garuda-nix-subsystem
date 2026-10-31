#!/usr/bin/env bash
# Turns the Arch guest into a Garuda-like host with an old Garuda Nix Subsystem,
# installed with the published garuda-nix-subsystem package.
# Usage (as root): provision-arch.sh
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

edition=${GNS_EDITION:-mokka}

if [ "$(stat -f -c %T /)" != "btrfs" ]; then
  echo "The root filesystem of the Arch image is not btrfs, the subsystem needs btrfs." >&2
  exit 1
fi

# Lima grows the disk image, but not the root partition and its btrfs. A full
# root makes Nix crash with a bus error during the subsystem install.
step "Growing the root filesystem to the full disk"
root_dev=$(findmnt -n -v -o SOURCE /)
root_disk="/dev/$(lsblk -n -o PKNAME "$root_dev")"
root_part=$(cat "/sys/class/block/$(basename "$root_dev")/partition")
pacman -Sy --noconfirm --needed cloud-guest-utils btrfs-progs
growpart "$root_disk" "$root_part" || true
btrfs filesystem resize max /

free_gib=$(($(stat -f -c %a /) * $(stat -f -c %S /) / 1073741824))

if [ "$free_gib" -lt 40 ]; then
  echo "Only $free_gib GiB free on /, the subsystem install needs about 40 GiB." >&2
  exit 1
fi

step "$free_gib GiB free on /"

step "Adding the chaotic-aur and garuda repositories"
pacman-key --init
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U --noconfirm --needed \
  https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst \
  https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst

if ! grep -q '^\[garuda\]' /etc/pacman.conf; then
  cat >>/etc/pacman.conf <<'EOF'

[garuda]
Include = /etc/pacman.d/chaotic-mirrorlist

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
fi

step "Installing garuda-nix-subsystem"
pacman -Syu --noconfirm --needed btrfs-progs git grub update-grub garuda-nix-subsystem

# The test source is mounted read-only and owned by the host user
git config --system --add safe.directory /mnt/src

# The package's installer (Lix, @nix, fstab), but with gns-install from the
# snapshot. Older published versions run nixos-install with CppNix, which
# crashes with SIGBUS against the host's Lix daemon.
step "Installing the subsystem ($edition, this takes a while)"
installer=$(mktemp)
sed -E "s|\"git\+https://[^\"]*#gns-install\"|\"$SRC_FLAKE#gns-install\"|" \
  /usr/lib/garuda/garuda-nix-subsystem/installer >"$installer"
grep -qF "$SRC_FLAKE#gns-install" "$installer"
bash "$installer" "$edition"
rm -f "$installer"

step "Switching the subsystem flake.nix to the old URL form"
uuid=$(findmnt -n -o UUID /)
mnt=$(mktemp -d)
mount -o subvol=@nix-subsystem "UUID=$uuid" "$mnt"
trap 'umount "$mnt"; rmdir "$mnt"' EXIT

sed -i -E "s|garuda\.url = \"[^\"]*\"|garuda.url = \"$OLD_GARUDA_URL\"|" "$mnt/etc/nixos/flake.nix"
grep -qF "$OLD_GARUDA_URL" "$mnt/etc/nixos/flake.nix"
commit_all "$mnt/etc/nixos" "Old garuda input URL"

step "Provisioned: subsystem flake.nix uses $OLD_GARUDA_URL"
