# Updating

Garuda Nix installs the `garuda-update` command on GUI systems and on systems managed through `garuda-managed.json`.
It is the convenient way to keep the system up to date.

```sh
garuda-update
```

## What it does

`garuda-update` itself is only a small launcher. On every run it fetches the latest updater from the `stable` branch of the [Garuda Nix repo](https://gitlab.com/garuda-linux/garuda-nix) and hands over to it. This allows us to fix common problems before the update starts, even on systems that have not been updated for a long time.

1. The updater is fetched with Nix. If Nix is unable to fetch it, the same updater is fetched with `git` and run without Nix. If both fail, the update is aborted and nothing is changed.
2. Fixes for known problems are applied, for example a flake input that uses a fetcher which no longer works. Files changed by a fix are backed up to `/var/lib/garuda/garuda-update/backups`.
3. The system is updated:
   - **NixOS flake setups**: updates the flake inputs, rebuilds with `nh os switch`, and commits the refreshed `flake.lock` when the flake lives in a Git repository. The flake defaults to `/etc/nixos` and can be pointed elsewhere with `GARUDA_FLAKE` or `--flake`.
   - **Managed systems** (`/etc/nixos/garuda-managed.json` exists): regenerates the managed configuration, updates the flake inputs and rebuilds.
4. Fixes that need the new system are applied and a notice is printed for every fix that changed something.

The output of every run is appended to `/var/log/garuda/garuda-update`.

When run as a normal user, `garuda-update` restarts itself with `sudo` and keeps `GARUDA_FLAKE`, `GARUDA_UPDATE_REF`, `GARUDA_UPDATE_NO_NIX` and `GARUDA_UPDATE_REPO`. A sudo rule that only allows `garuda-update` itself needs the `SETENV` tag for these variables, otherwise sudo refuses to run it while one of them is set. Rules for `ALL` commands, like the default one for the `wheel` group, include it. `--flake` works without `SETENV`.

## The updater

The updater lives in [`packages/garuda-update`](https://gitlab.com/garuda-linux/garuda-nix/-/tree/main/packages/garuda-update) and is the same for NixOS flake setups, managed systems and the subsystem:

| File          | Purpose                                                                                       |
| ------------- | --------------------------------------------------------------------------------------------- |
| `launcher.sh` | The `garuda-update` command installed on the system. Fetches the updater and starts it.       |
| `runner.py`   | The updater. Detects the kind of system, applies the fixes and runs the update.               |
| `fixes.py`    | The list of fixes. Every fix checks whether it is needed, applies itself and leaves a notice. |
| `nixedit.py`  | Helpers to change Nix files without touching comments or formatting.                          |

Fixes are applied without asking. Which fixes a system has already received is tracked in `/var/lib/garuda/garuda-update/intervention_sequence`, so a fix is only applied once. A fix that fails is skipped and tried again on the next update, it never stops the update itself.

It can also be started directly, which is the same as running `garuda-update`:

```sh
sudo nix run "gitlab:garuda-linux/garuda-nix/stable#garuda-update-runner"
```

### Testing changes to the updater

These variables are meant for testing the updater itself:

| Variable                 | Effect                                                         |
| ------------------------ | -------------------------------------------------------------- |
| `GARUDA_UPDATE_REPO`     | Fetch the updater from another repository, e.g. a local clone. |
| `GARUDA_UPDATE_REF`      | Fetch another branch than `stable`.                            |
| `GARUDA_UPDATE_NO_NIX=1` | Skip the Nix fetch to test the `git` fallback.                 |

## Fixes

### Repository rename (`repo-rename`)

The repository was renamed from `garuda-nix-subsystem` to `garuda-nix`. GitLab still redirects the old name, but only for as long as nothing else claims it. The fix points every input in `flake.nix` that uses the old name of our repository to the new one, whatever fetcher it uses:

```diff
- garuda.url = "gitlab:garuda-linux/garuda-nix-subsystem/stable";
+ garuda.url = "gitlab:garuda-linux/garuda-nix/stable";
```

A `git+https://gitlab.com/garuda-linux/garuda-nix-subsystem.git?ref=stable` input becomes `git+https://gitlab.com/garuda-linux/garuda-nix.git?ref=stable` the same way. Repositories of other owners with the same name are left alone.

#### Applying it manually

No action is needed, `garuda-update` applies it on the next update. To do it by hand, replace `garuda-nix-subsystem` with `garuda-nix` in the `garuda` input of `/etc/nixos/flake.nix` and run `sudo nix flake update garuda --flake /etc/nixos`.

## Rolling back

Roll back to the previous generation (only on standalone NixOS):

```sh
garuda-update --rollback
```

## Subsystem

On a Garuda subsystem, `garuda-update` runs from inside Garuda Nix with the managed path described above. The update can also be triggered from the Garuda host with `sudo garuda-nix-subsystem update`.
