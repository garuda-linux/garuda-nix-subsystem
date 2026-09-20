# Updating

Garuda Nix installs the `garuda-update` command on GUI systems and on systems managed through `garuda-managed.json`.
It is the a convenient way to keep the system up to date.

```sh
garuda-update
```

## What it does

- **NixOS flake setups**: updates the flake inputs, rebuilds with `nh os switch`, and commits the refreshed `flake.lock` when the flake lives in a Git repository. The flake defaults to `/etc/nixos` and can be pointed elsewhere with `GARUDA_FLAKE`.
- **Managed systems** (`/etc/nixos/garuda-managed.json` exists): downloads the latest updater from the `stable` branch and runs it. This regenerates the managed configuration, updates the flake inputs and rebuilds.

## Rolling back

Roll back to the previous generation (only on standalone NixOS):

```sh
garuda-update --rollback
```

## Subsystem

On a Garuda subsystem, `garuda-update` runs from inside Garuda Nix with the managed path described above. The update can also be triggered from the Garuda host with `sudo garuda-nix-subsystem update`.
