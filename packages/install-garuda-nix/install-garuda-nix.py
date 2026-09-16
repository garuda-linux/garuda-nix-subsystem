#!/usr/bin/env python3
"""install-garuda-nix: partition, configure and install Garuda NixOS.

Re-runs itself with sudo when not root. With --disk it wipes and
partitions (picking disk and schema interactively when not given),
then generates the system config from the shared installer template
and runs nixos-install, setting the user password at the end:

  install-garuda-nix --edition mokka --feature gaming \\
      --hostname myhost --username alice --disk /dev/sda
"""

import argparse
import os
import subprocess
import sys


def repo_path(name):
    """Locate the shared installer-lib/template: packaged location via
    env first, source-tree relative path as fallback."""
    env = os.environ.get(
        "GNS_INSTALLER_LIB" if name == "installer-lib" else "GNS_TEMPLATE_DIR"
    )
    if env:
        return env
    return os.path.normpath(
        os.path.join(
            os.path.dirname(os.path.abspath(__file__)),
            "..",
            "calamares-nixos-extensions",
            name,
        )
    )


sys.path.insert(0, repo_path("installer-lib"))
import garuda_partition as gp
import garuda_progress as gprog
import garuda_template as gt

try:
    import questionary
except ImportError:
    questionary = None


def ensure_root():
    if os.geteuid() != 0:
        print("need root, re-running with sudo ...")
        carry = [f"{k}={os.environ[k]}" for k in
                 ("GNS_INSTALLER_LIB", "GNS_TEMPLATE_DIR", "PATH")
                 if k in os.environ]
        os.execvp("sudo", ["sudo", "env"] + carry +
                  [sys.argv[0]] + sys.argv[1:])


def host_timezone():
    try:
        target = os.readlink("/etc/localtime")
        marker = "zoneinfo/"
        if marker in target:
            return target.split(marker, 1)[1]
    except OSError:
        pass
    return None


def build_parser():
    p = argparse.ArgumentParser(
        prog="install-garuda-nix",
        description="Generate a Garuda NixOS config from the shared installer template.",
    )
    p.add_argument("--edition", choices=("mokka", "dr460nized", "catppuccin"), default=None,
                   help="asked interactively when missing")
    p.add_argument("--preset", choices=gt.GARUDA_PRESETS, default=None)
    p.add_argument(
        "--feature",
        action="append",
        default=[],
        metavar="FEATURE",
        help=f"repeatable, one of: {', '.join(sorted(gt.GARUDA_FEATURES))}",
    )
    p.add_argument("--root", default="/mnt", help="target mount point (default: /mnt)")
    p.add_argument("--disk", default=None,
                   help="wipe and partition this disk before installing "
                        "(e.g. /dev/sda). If not specified and <root> is not "
                        "mounted, pick from a list")
    p.add_argument("--schema", choices=gp.SCHEMAS, default=None,
                   help="partitioning schema for --disk "
                        f"(asked when missing, default: {gp.DEFAULT_SCHEMA})")
    p.add_argument("--luks-pass-file", default=None,
                   help="file with the LUKS passphrase (else prompted)")
    p.add_argument("--yes", action="store_true",
                   help="skip the disk-wipe confirmation (dangerous)")
    p.add_argument("--hostname", default="garuda-nix")
    p.add_argument("--username", default="garuda")
    p.add_argument("--fullname", default=None)
    p.add_argument(
        "--no-autologin", action="store_true", help="disable display-manager autologin"
    )
    p.add_argument(
        "--timezone",
        default=host_timezone(),
        help="default: host's /etc/localtime zone",
    )
    p.add_argument("--locale", default=None)
    p.add_argument("--xkb-layout", default=None)
    p.add_argument("--xkb-variant", default=None)
    p.add_argument("--vconsole", default=None)
    p.add_argument(
        "--bootloader",
        choices=("auto", "systemd-boot", "grub", "none"),
        default="auto",
        help="auto: systemd-boot on UEFI, otherwise grub needs --grub-device",
    )
    p.add_argument(
        "--grub-device", default=None, help="e.g. /dev/sda for BIOS installs"
    )
    p.add_argument("--kernel", choices=("cachyos", "lts", "latest"), default="cachyos")
    p.add_argument(
        "--flake-ref",
        default=os.environ.get("GNS_FLAKE_REF", gt.DEFAULT_FLAKE_REF),
    )
    p.add_argument("--state-version", default=None)
    p.add_argument(
        "--allow-unfree",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="keep unfree packages (default: True, --no-allow-unfree to flip)",
    )
    p.add_argument(
        "--install",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="run nixos-install --flake <root>/etc/nixos#<hostname> "
             "afterwards (default: True, --no-install to skip)",
    )
    p.add_argument(
        "--no-bootloader",
        action="store_true",
        help="pass --no-bootloader to nixos-install (test VMs without EFI vars)",
    )
    p.add_argument(
        "--tui", action="store_true",
        help="force the interactive wizard even when all flags are given",
    )
    p.add_argument(
        "--password-file", default=None,
        help="read the user password from this file (non-interactive)",
    )
    return p


def pick_disk(root):
    disks = gp.list_disks()
    if not disks:
        print(f"error: {root} is not mounted and no disks found",
              file=sys.stderr)
        raise SystemExit(1)
    if len(disks) == 1:
        return disks[0][0]
    print(f"error: {root} is not mounted, pick one: " +
          ", ".join(d for d, _ in disks), file=sys.stderr)
    raise SystemExit(1)


def pick_schema():
    return gp.DEFAULT_SCHEMA


def read_password(username):
    import getpass
    first = getpass.getpass(f"Password for {username}: ")
    second = getpass.getpass("Repeat password: ")
    if not first or first != second:
        print("error: passwords do not match or are empty", file=sys.stderr)
        return None
    return first


def set_password(root, username, password):
    subprocess.run(
        ["nixos-enter", "--root", root, "-c", "chpasswd"],
        input=f"{username}:{password}\n".encode(), check=True,
    )


def main(argv=None):
    args = build_parser().parse_args(argv)
    ensure_root()

    if args.password_file:
        with open(args.password_file) as f:
            args.password = f.read().splitlines()[0]
    else:
        args.password = None
    args.root_mounted = os.path.ismount(args.root)

    wizard_confirmed = False
    needs = (args.edition is None or args.disk is None or
             args.schema is None or args.password is None)
    if args.tui or (needs and sys.stdin.isatty()):
        if questionary is None:
            print("error: questionary is not installed, pass all flags "
                  "explicitly", file=sys.stderr)
            return 1
        import garuda_tui as gtui
        try:
            gtui.run_wizard(questionary, args,
                            ("mokka", "dr460nized", "catppuccin"),
                            gt.GARUDA_FEATURES, gt.GARUDA_PRESETS,
                            gp.list_disks(), gp.SCHEMAS)
        except gtui.Aborted as e:
            print(f"error: {e}", file=sys.stderr)
            return 1
        wizard_confirmed = args.disk is not None

    unknown = [f for f in args.feature if f not in gt.GARUDA_FEATURES]
    if unknown:
        print(
            f"error: unknown feature(s): {', '.join(unknown)}. Choose from: {', '.join(sorted(gt.GARUDA_FEATURES))}",
            file=sys.stderr,
        )
        return 1
        
    try:
        gt.check_preset_features(args.preset, args.feature)
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    if args.bootloader == "grub" and not args.grub_device:
        print("error: --bootloader grub needs --grub-device", file=sys.stderr)
        return 1
    if args.bootloader == "auto":
        efi = os.path.isdir("/sys/firmware/efi")
        bootloader = "systemd-boot" if efi else ("grub" if args.grub_device else "none")
        if bootloader == "none":
            print(
                "warning: no UEFI detected and no --grub-device given, "
                "writing config without bootloader"
            )
    else:
        bootloader = args.bootloader

    state_version = args.state_version
    if state_version is None:
        try:
            out = subprocess.check_output(
                ["nixos-version"], text=True
            ).split(".")[:2]
            state_version = ".".join(out)[:5] or "26.11"
        except (subprocess.CalledProcessError, OSError):
            state_version = "26.11"

    disk = args.disk
    if disk is None and not os.path.ismount(args.root):
        disk = pick_disk(args.root)
    schema = args.schema
    if disk is not None and schema is None:
        schema = pick_schema()
    if disk is not None:
        efi = gp.partition_disk(disk, schema, args.root,
                                luks_pass_file=args.luks_pass_file,
                                assume_yes=args.yes or wizard_confirmed)
        if not efi and args.bootloader == "auto" and not args.grub_device:
            args.grub_device = disk

    try:
        opts = gt.InstallOpts(
        edition=args.edition,
        preset=args.preset,
        features=args.feature,
        root=args.root,
        hostname=args.hostname,
        username=args.username,
        state_version=state_version,
        flake_ref=args.flake_ref,
        allow_unfree=args.allow_unfree,
        bootloader=bootloader,
        grub_device=args.grub_device,
        kernel=args.kernel,
        timezone=args.timezone,
        locale=args.locale,
        xkb_layout=args.xkb_layout,
        xkb_variant=args.xkb_variant,
        vconsole=args.vconsole,
        fullname=args.fullname,
        autologin=not args.no_autologin,
        tmpfs_root=gp.is_tmpfs_root(schema),
    )
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    hooks = gt.Hooks()
    nixos_dir = os.path.join(args.root, "etc/nixos")
    print(f"Generating hardware configuration for {args.root} ...")
    subprocess.check_call(
        ["nixos-generate-config", "--root", args.root],
        stderr=subprocess.STDOUT,
    )
    template_dir = repo_path("template")
    gt.write_config(template_dir, nixos_dir, opts, hooks)
    print(f"Wrote {nixos_dir}")

    if args.install:
        flake = os.path.join(args.root, "etc/nixos") + "#" + args.hostname
        subprocess.check_call(
            ["nix", "flake", "lock"],
            cwd=os.path.join(args.root, "etc/nixos"),
        )
        print(f"Running nixos-install --flake {flake} ...")
        cmd = [
            "nixos-install",
            "--flake",
            flake,
            "--root",
            args.root,
            "--no-root-passwd",
            "--option",
            "max-jobs",
            "2",
            "--log-format",
            "internal-json",
        ]
        if args.no_bootloader:
            cmd.append("--no-bootloader")
        rc = gprog.run(cmd)
        if rc != 0:
            return rc
        password = args.password
        if password is None and sys.stdin.isatty():
            password = read_password(args.username)
            if password is None:
                return 1
        if password is not None:
            set_password(args.root, args.username, password)
            print(f"Password set for {args.username}")
        else:
            print(
                f"Set a password with `nixos-enter --root {args.root} -c "
                f"'passwd {args.username}'`"
            )
        return 0
    else:
        print(
            f"Set a password with `nixos-enter --root {args.root} -c 'passwd {args.username}'`,"
        )
        print("then install with:")
        print(
            f"  nixos-install --flake {os.path.join(args.root, 'etc/nixos')}#{args.hostname} --root {args.root} --no-root-passwd"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
