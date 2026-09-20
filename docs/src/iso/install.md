# Installing

Two frontends install the same Garuda flake. Pick one:

## Calamares (GUI)

The graphical installer keeps it simple on purpose: pick an edition
(`mokka`, `dr460nized`) and pick optional features
(`gaming`, `printing`, …). Further customization can be done after the
installation is complete.

## install-garuda-nix (CLI)

The command-line installer covers everything the GUI does, plus:

- **Presets**
  - Choose from `desktop`, `laptop`, `server`, or `handheld`
- **Partition layouts**
  - Choose from `ext4`, `btrfs`, `luks-ext4`, `luks-btrfs`, `btrfs-impermanence`, `luks-btrfs-impermanence`, `ext4-impermanence`, `luks-ext4-impermanence`
  - Choosing [impermanence](https://github.com/nix-community/impermanence) automatically sets up either btrfs rollback or root on tmpfs
- **Passwords**
  - The user (`--password`) and root (`--root-password`) passwords are hashed with yescrypt and written into the generated config, so they survive impermanence/rollback

This can either be done interactively or non-interactively.

Example:

```sh
sudo install-garuda-nix --edition mokka --preset desktop \
  --feature gaming --feature printing \
  --hostname mypc --username nico \
  --disk /dev/sda --schema btrfs --install
```

## All options

```sh
usage: install-garuda-nix [-h] [--edition {mokka,dr460nized}] [--preset {desktop,laptop,server,handheld}]
                          [--feature FEATURE] [--root ROOT] [--disk DISK]
                          [--schema {ext4,btrfs,luks-ext4,luks-btrfs,btrfs-impermanence,luks-btrfs-impermanence,ext4-impermanence,luks-ext4-impermanence}]
                          [--luks-pass-file LUKS_PASS_FILE] [--yes] [--hostname HOSTNAME] [--username USERNAME]
                          [--fullname FULLNAME] [--no-autologin] [--timezone TIMEZONE] [--locale LOCALE]
                          [--xkb-layout XKB_LAYOUT] [--xkb-variant XKB_VARIANT] [--vconsole VCONSOLE]
                          [--bootloader {auto,systemd-boot,grub,none}] [--grub-device GRUB_DEVICE]
                          [--kernel {cachyos,lts,latest}] [--flake-ref FLAKE_REF] [--state-version STATE_VERSION]
                          [--allow-unfree | --no-allow-unfree] [--install | --no-install] [--no-bootloader] [--tui]
                          [--password PASSWORD] [--root-password ROOT_PASSWORD]

Generate a Garuda NixOS config from the shared installer template.

options:
  -h, --help            show this help message and exit
  --edition {mokka,dr460nized}
                        asked interactively when missing
  --preset {desktop,laptop,server,handheld}
  --feature FEATURE     repeatable, one of: btrfs-maintenance, gaming, impermanence, performance, powersave, printing,
                        samba, scanning
  --root ROOT           target mount point (default: /mnt)
  --disk DISK           wipe and partition this disk before installing (e.g. /dev/sda). If not specified and <root> is
                        not mounted, pick from a list
  --schema {ext4,btrfs,luks-ext4,luks-btrfs,btrfs-impermanence,luks-btrfs-impermanence,ext4-impermanence,luks-ext4-impermanence}
                        partitioning schema for --disk (asked when missing, default: btrfs)
  --luks-pass-file LUKS_PASS_FILE
                        file with the LUKS passphrase (else prompted)
  --yes                 skip the disk-wipe confirmation (dangerous)
  --hostname HOSTNAME
  --username USERNAME
  --fullname FULLNAME
  --no-autologin        disable display-manager autologin
  --timezone TIMEZONE   default: host's /etc/localtime zone
  --locale LOCALE
  --xkb-layout XKB_LAYOUT
  --xkb-variant XKB_VARIANT
  --vconsole VCONSOLE
  --bootloader {auto,systemd-boot,grub,none}
                        auto: systemd-boot on UEFI, otherwise grub needs --grub-device
  --grub-device GRUB_DEVICE
                        e.g. /dev/sda for BIOS installs
  --kernel {cachyos,lts,latest}
  --flake-ref FLAKE_REF
  --state-version STATE_VERSION
  --allow-unfree, --no-allow-unfree
                        keep unfree packages (default: True, --no-allow-unfree to flip)
  --install, --no-install
                        run nixos-install --flake <root>/etc/nixos#<hostname> afterwards (default: True, --no-install to
                        skip)
  --no-bootloader       pass --no-bootloader to nixos-install (test VMs without EFI vars)
  --tui                 force the interactive wizard even when all flags are given
  --password PASSWORD   set the user password non-interactively
  --root-password ROOT_PASSWORD
                        set the root password non-interactively
```

## Install from the flake

On any NixOS host with internet, run the installer directly from the published flake:

```sh
sudo nix run gitlab:garuda-linux/garuda-nix-subsystem/stable#install-garuda-nix -- \
  --edition mokka --hostname mypc --username nico --install
```

`--flake-ref` defaults to that same `stable` ref, so the generated config already points at it: future rebuilds are just `nixos-rebuild switch --flake /etc/nixos#mypc`. Pass `--flake-ref gitlab:garuda-linux/garuda-nix-subsystem/stable` (or any ref) to track a different branch instead.

## Module options

Both installers write a flake config built from the same template; what
lands in `configuration.nix` is controlled by the
[module options reference](../nixos-module/options.md)
(`garuda.gaming.enable`, `garuda.impermanence.*`, …). Presets and
features are just shortcuts that flip those options on.
