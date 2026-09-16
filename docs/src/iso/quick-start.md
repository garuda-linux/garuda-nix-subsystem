# Installer ISO

The flake can build an installer ISO for three editions:

- `mokka`
- `dr460nized`
- `catppuccin`

The ISO boots to the desktop. Calamares starts automatically.

The installer uses our own calamares-nixos-extensions. They install the Garuda flake instead of a plain NixOS configuration.

## Build

Build from the dev shell:

```sh
nix develop -c buildiso mokka
```

Replace `mokka` with `dr460nized` or `catppuccin` to build another edition. Use `buildiso all` to build all three.

Append `--run` to boot the freshly built ISO in QEMU instead of just copying it:

```sh
nix develop -c buildiso mokka --run
```

The command copies the ISO to the current working directory.

Alternatively, build the ISO directly with Nix:

```sh
nix build .#internal.iso-mokka
nix build .#internal.iso-dr460nized
nix build .#internal.iso-catppuccin
```

## Boot

Write the ISO to a USB drive:

```sh
sudo dd if=$name.iso of=/dev/$usb bs=4M status=progress oflag=sync
```

Replace `$usb` with your USB drive, and `$name` with the resulting ISO file. This destroys all data on the drive.

## Install from an existing NixOS system

No ISO needed: `install-garuda-nix` generates the same Garuda config the Calamares installer writes, on any NixOS host. Available in the dev shell, or via `nix run .#install-garuda-nix`:

```sh
sudo install-garuda-nix --edition mokka --feature gaming --feature printing \
  --hostname mypc --username nico --install
```

Pass `--disk /dev/sdX --schema btrfs` to partition automatically (ext4, btrfs, LUKS variants, and `-impermanence` schemas available), or partition and mount your target at `/mnt` yourself first (override with `--root`). The command writes the flake config to `<root>/etc/nixos`, runs `nixos-generate-config` hardware + `nixos-facter` GPU/NVIDIA detection, and with `--install` runs `nixos-install --flake <root>/etc/nixos#<hostname>` afterwards.

## Install straight from the flake

On any NixOS host with internet, run the installer directly from the published flake:

```sh
sudo nix run gitlab:garuda-linux/garuda-nix-subsystem/stable#install-garuda-nix -- \
  --edition mokka --hostname mypc --username nico --install
```

`--flake-ref` defaults to that same `stable` ref, so the generated config already points at it: future rebuilds are just `nixos-rebuild switch --flake /etc/nixos#mypc`. Pass `--flake-ref gitlab:garuda-linux/garuda-nix-subsystem/stable` (or any ref) to track a different branch instead.
