# Quick start

## Intro

The original idea behind this project was to use NixOS as a subsystem of Garuda. This means it can be installed easily from a running Garuda installation. This all works via BTRFS subvolumes, therefore any OS other than Garuda is considered unsupported for this method. Settings like users, passwords, and locales are automatically derived from Garuda and change with it. An option to partly share the `/home` partition between Garuda and NixOS has also been provided.

At the time of writing, setting up a dr460nized desktop is the only option. This may or may not change in the future.

## Installation

Our repo contains `garuda-nix-subsystem`, which is the needed part to get going:

```sh
sudo pacman -S garuda-nix-subsystem # get the package
garuda-nix-subsystem install # trigger the installation process
```

The script will first install Nix, the package manager, and proceed by setting up the required subvolumes. After the process is finished, the subsystem may now be entered by rebooting and selecting the new `Garuda Nix Subsystem` entry in GRUB.

## Updating

The system may be updated by running `sudo garuda-nix-subsystem update` from either Garuda or Garuda Nix Subsystem. This sources the latest tagged commit from our [Garuda Nix Subsystem repo](https://gitlab.com/garuda-linux/garuda-nix-subsystem), which also updates the flake's inputs and therefore all package versions.
