# Getting the ISO

## Download

The ISO can be downloaded from our [builds page page](https://builds.garudalinux.org/garuda-nix/).
Available build types:

- `garuda-nix-dr460nized-26.11-x86_64-linux.iso`: these are built daily and point to our latest stable tag, which is only tagged if evaluation and a few other checks pass

## Flash & Boot

Write the ISO to a USB drive:

```sh
sudo dd if=$name.iso of=/dev/$usb bs=4M status=progress oflag=sync
```

Replace `$usb` with your USB drive, and `$name` with the resulting ISO file. This destroys all data on the drive.

Once booted, continue with [installing](./install.md).

## Build

The flake can build an installer ISO for three editions:

- `mokka`
- `dr460nized`
- `catppuccin`

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
