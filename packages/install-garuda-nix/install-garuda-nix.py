#!/usr/bin/env python3
"""install-garuda-nix: generate a Garuda NixOS system config from the CLI.

Same template-filling core as the Calamares installer, for manual
installs: partition and mount the target yourself, then run (as root):

  install-garuda-nix --flavor mokka --feature gaming --feature printing \\
      --hostname myhost --username alice --root /mnt

This runs nixos-generate-config, probes the hardware with nixos-facter
(auto-enables the NVIDIA driver on detection), and writes the filled
flake to <root>/etc/nixos. Afterwards install with e.g.:

  nixos-install --flake /mnt/etc/nixos#myhost --root /mnt --no-root-passwd

or pass --install to run that directly.
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
import garuda_template as gt


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
    p.add_argument("--flavor", choices=("mokka", "dr460nized", "catppuccin"), required=True)
    p.add_argument("--preset", choices=gt.GARUDA_PRESETS, default=None)
    p.add_argument(
        "--feature",
        action="append",
        default=[],
        metavar="FEATURE",
        help=f"repeatable, one of: {', '.join(sorted(gt.GARUDA_FEATURES))}",
    )
    p.add_argument("--root", default="/mnt", help="target mount point (default: /mnt)")
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
        action="store_true",
        help="run nixos-install --flake <root>/etc/nixos#<hostname> afterwards",
    )
    p.add_argument(
        "--no-bootloader",
        action="store_true",
        help="pass --no-bootloader to nixos-install (test VMs without EFI vars)",
    )
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)

    unknown = [f for f in args.feature if f not in gt.GARUDA_FEATURES]
    if unknown:
        print(
            f"error: unknown feature(s): {', '.join(unknown)}. Choose from: {', '.join(sorted(gt.GARUDA_FEATURES))}",
            file=sys.stderr,
        )
        return 1

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

    opts = gt.InstallOpts(
        flavor=args.flavor,
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
    )

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
        ]
        if args.no_bootloader:
            cmd.append("--no-bootloader")
        subprocess.check_call(cmd)
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
