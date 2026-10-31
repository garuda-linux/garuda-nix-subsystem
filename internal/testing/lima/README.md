# Lima tests

Lima VMs that run `garuda-update` from the working tree against old Garuda Nix installs.

```sh
nix develop          # provides limatest and limactl
limatest flake       # provision (first run) or restore the VM, then open a shell
limatest flake --check
```

| Scenario        | VM            | What runs                                                                                                                                        |
| --------------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `flake`         | `gns-flake`   | Headless Garuda Nix flake setup in `/etc/nixos`, launcher from the snapshot                                                                      |
| `fallback`      | `gns-flake`   | Same, with `GARUDA_UPDATE_NO_NIX=1` (git clone path)                                                                                             |
| `managed`       | `gns-managed` | Headless managed system with `garuda-managed.json`, extra btrfs disk with `@home` as the host filesystem                                         |
| `host`          | `gns-arch`    | Arch with the published `garuda-nix-subsystem` package (its installer runs `gns-install` from the snapshot), then the `gns-update` devshell path |
| `host-fallback` | `gns-arch`    | Same VM, runner from a git clone with tree-sitter-nix from `nix shell` (git clone fallback of the Arch package's updater)                        |
| `fix-fails`     | `gns-flake`   | `flake.nix` immutable, so `repo-rename` fails: skipped with a warning, no sequence written, applied on the next run                              |
| `rebuild-fails` | `gns-flake`   | Failing assertion in `configuration.nix`: update fails, sequence not written, running system unchanged                                           |
| `fetch-fails`   | `gns-flake`   | Launcher repository does not exist: Nix and git fetch fail, abort, nothing changed                                                               |
| `rollback`      | `gns-flake`   | Update, then `garuda-update --rollback` goes back one generation                                                                                 |
| `sudo-setenv`   | `gns-flake`   | Sudo rule for the launcher only, no `SETENV`: refused with `GARUDA_*` set, accepted without (no network, nothing changes)                        |
| `modules`       | `gns-flake`   | Garuda input switched to the snapshot, so the update builds and switches to the current modules (Lix, no evaluation warnings)                    |

## How it works

- Every run copies the working tree to branch `lima-test` of `.lima/_src.git` (tracked files including intent-to-add ones, staged and unstaged, no untracked files). The VM mounts it read-only at `/mnt/src`, and this directory at `/mnt/lima`.
- The guest runs the updater with `GARUDA_UPDATE_REPO=file:///mnt/src` and `GARUDA_UPDATE_REF=lima-test`, so the launcher and the runner use the same code paths as on user systems.
- The first run of a VM provisions an old install: Garuda Nix from `stable` under the old repo name `garuda-nix-subsystem.git` (`GNS_OLD_REF` picks another ref), then `flake.nix` gets the old `gitlab:garuda-linux/garuda-nix-subsystem/stable` input. The VM is saved as Lima snapshot `old-install`, and later runs restore it. `--keep` skips the restore, `--reprovision` starts over.
- VMs live in `.lima/` in the repository (`LIMA_HOME`).
- NixOS guests use the [nixos-lima](https://github.com/nixos-lima/nixos-lima) image and module (`v0.2.2`). The Arch guest uses Lima's `archlinux` template and needs its btrfs root.
