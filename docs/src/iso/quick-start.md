# Installer ISO

The flake can build an installer ISO for two flavours:

- `dr460nized`
- `mokka`

The ISO boots to the desktop. Calamares starts automatically.

The installer uses our own calamares-nixos-extensions. They install the Garuda flake instead of a plain NixOS configuration.

## Build

Build from the dev shell:

```sh
nix develop -c buildiso dr460nized
```

Replace `dr460nized` with `mokka` to build the other flavour. Use `buildiso all` to build both.

The command copies the ISO to the current working directory.

Alternatively, build the ISO directly with Nix:

```sh
nix build .#internal.iso-dr460nized
nix build .#internal.iso-mokka
```

## Boot

Write the ISO to a USB drive:

```sh
sudo dd if=$name.iso of=/dev/$usb bs=4M status=progress oflag=sync
```

Replace `$usb` with your USB drive, and `$name` with the resulting ISO file. This destroys all data on the drive.
