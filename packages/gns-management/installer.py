#!/usr/bin/env python3
import argparse
import os
import sys


def repo_path():
    env = os.environ.get("GNS_INSTALLER_LIB")
    if env:
        return env
    return os.path.normpath(os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "..", "garuda-installer-lib"))


sys.path.insert(0, repo_path())
import garuda_subsystem as gs
import garuda_template as gt

try:
    import questionary
except ImportError:
    questionary = None


def build_parser():
    p = argparse.ArgumentParser(
        prog="gns-install",
        description="Install the Garuda Nix Subsystem onto the host BTRFS.",
    )
    p.add_argument("edition", nargs="?", choices=gt.SUBSYSTEM_EDITIONS,
                   default=None, help="asked interactively when missing")
    p.add_argument("--preset", choices=gt.GARUDA_PRESETS, default=None)
    p.add_argument("--feature", action="append", default=[], metavar="FEATURE",
                   help="repeatable, one of: " + ", ".join(sorted(
                       set(gt.GARUDA_FEATURES) - gt.SUBSYSTEM_EXCLUDED_FEATURES)))
    p.add_argument("--hostname", default=None, help="default: /etc/hostname")
    p.add_argument("--flake-ref",
                   default=os.environ.get("GNS_FLAKE_REF", gt.DEFAULT_FLAKE_REF))
    p.add_argument("--state-version", default=gt.SUBSYSTEM_STATE_VERSION)
    p.add_argument("--force", "-f", "--reinstall", dest="force",
                   action="store_true", help="reinstall over existing system")
    p.add_argument("--tui", action="store_true",
                   help="force the interactive wizard")
    return p


def run_wizard(args):
    if questionary is None:
        print("error: questionary is not installed, pass all flags explicitly",
              file=sys.stderr)
        return 1
    try:
        if args.edition is None:
            args.edition = questionary.select(
                "Edition:", choices=list(gt.SUBSYSTEM_EDITIONS)).ask()
            if args.edition is None:
                raise ValueError("aborted by user")
        if args.preset is None and not args.feature:
            picked = questionary.select(
                "Preset:", choices=["none"] + list(gt.GARUDA_PRESETS)).ask()
            if picked is None:
                raise ValueError("aborted by user")
            args.preset = None if picked == "none" else picked
        if not args.feature:
            choices = sorted(set(gt.GARUDA_FEATURES) - gt.SUBSYSTEM_EXCLUDED_FEATURES)
            if args.preset in gt.PRESET_EXCLUDES:
                choices = [c for c in choices
                           if c != gt.PRESET_EXCLUDES[args.preset]]
            args.feature = questionary.checkbox(
                "Features (space to toggle):", choices=choices).ask() or []
            if not args.feature and not questionary.confirm(
                    "No features selected. Continue?",
                    default=True).ask():
                raise ValueError("aborted by user")
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    return 0


def default_hostname():
    try:
        with open("/etc/hostname") as f:
            host = f.read().strip() or "garuda-nix"
    except OSError:
        host = "garuda-nix"
    return host if host.endswith("-nix") else f"{host}-nix"


def main(argv=None):
    args = build_parser().parse_args(argv)
    gs.ensure_root()
    gs.prepare_dirs()

    if not args.force and os.environ.get("GNS_FORCE") == "true":
        args.force = True
    if args.edition is None:
        args.edition = os.environ.get("GNS_EDITION")
    if args.hostname is None:
        args.hostname = default_hostname()

    needs_wizard = args.tui or (args.edition is None and sys.stdin.isatty())
    if needs_wizard and (rc := run_wizard(args)):
        return rc
    if args.edition is None:
        args.edition = "dr460nized"

    unknown = [f for f in args.feature if f not in gt.GARUDA_FEATURES]
    if unknown:
        print(f"error: unknown feature(s): {', '.join(unknown)}. "
              f"Choose from: {', '.join(sorted(gt.GARUDA_FEATURES))}",
              file=sys.stderr)
        return 1
    try:
        gt.check_subsystem_features(args.feature)
        gt.check_preset_features(args.preset, args.feature)
        gt.check_feature_conflicts(args.feature)
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    uuid = gs.btrfs_uuid()
    gs.step("Mounting Garuda Nix Subsystem subvolumes")
    gs.ensure_subvolume(uuid)
    mnt = gs.mount_subsystem(uuid)
    gs.step("Configuring Garuda Nix Subsystem")

    nixos_dir = os.path.join(mnt, "etc/nixos")
    os.makedirs(nixos_dir, exist_ok=True)
    managed = os.path.join(nixos_dir, "garuda-managed.json")
    if os.path.exists(managed):
        installed = (os.path.exists(os.path.join(mnt, "nix/var/nix/profiles/system"))
                     or os.path.exists(os.path.join(mnt, "boot/grub/grub.cfg")))
        if installed and not args.force:
            print("error: Garuda Nix Subsystem is already installed. "
                  "Pass --force to reinstall.", file=sys.stderr)
            return 1
        if installed:
            gs.step("Forcing reinstall over existing installation")
        else:
            gs.step("Previous incomplete install detected, resuming")

    gt.write_subsystem_config(
        nixos_dir, edition=args.edition, preset=args.preset,
        features=args.feature, hostname=args.hostname,
        state_version=args.state_version, flake_ref=args.flake_ref,
        install_version=os.environ.get("GNS_VERSION", "2"))

    hw = os.path.join(nixos_dir, "hardware-configuration.nix")
    if not os.path.exists(hw):
        gs.run(["nixos-generate-config", "--root", mnt])

    gs.git_commit(nixos_dir, "Initial Garuda Nix Subsystem configuration")

    env = dict(os.environ, GNS_MNT_DIR=mnt, GNS_BTRFS_UUID=uuid,
               GNS_FROM_HOST="true", GNS_INSTALLING="true")
    os.execvpe("gns-update", ["gns-update"], env)


if __name__ == "__main__":
    sys.exit(main())
