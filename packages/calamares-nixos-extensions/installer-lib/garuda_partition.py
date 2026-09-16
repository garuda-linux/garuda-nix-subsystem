#!/usr/bin/env python3
"""Disk partitioning for install-garuda-nix.

Manual parted/mkfs/cryptsetup with four schemas:
- ext4, btrfs (default), luks-ext4, luks-btrfs.
"""

import getpass
import os
import shutil
import subprocess

SCHEMAS = ("ext4", "btrfs", "luks-ext4", "luks-btrfs")
DEFAULT_SCHEMA = "btrfs"

ESP_SIZE = "512MiB"
LUKS_MAPPER_NAME = "garuda-root"


class PartitionError(Exception):
    pass


def is_efi(path="/sys/firmware/efi"):
    return os.path.isdir(path)


def require_tools():
    tools = ["parted", "mkfs.fat", "mkfs.ext4", "mkfs.btrfs", "btrfs",
             "cryptsetup", "mount", "umount"]
    missing = [t for t in tools if shutil.which(t) is None]
    if missing:
        raise PartitionError(
            f"missing tools: {', '.join(missing)} (need parted, dosfstools, "
            "e2fsprogs, btrfs-progs, cryptsetup)"
        )


def plan_partitions(schema, efi=True):
    """Pure layout plan: [(number, label, fs, mountpoint)]. Number 0 is
    the boot stub (ESP on EFI, bios-boot on BIOS)."""
    if schema not in SCHEMAS:
        raise PartitionError(
            f"unknown schema {schema!r}, choose from: {', '.join(SCHEMAS)}"
        )
    fs = "ext4" if "ext4" in schema else "btrfs"
    boot = ("esp", "vfat", "/boot") if efi else ("bios-boot", None, None)
    return [boot, ("root", fs, "/")]


def _run(cmd, **kwargs):
    subprocess.check_call(cmd, **kwargs)


def _read_luks_passphrase(pass_file=None):
    if pass_file:
        with open(pass_file) as f:
            return f.read().strip("\n")
    first = getpass.getpass("LUKS passphrase: ")
    second = getpass.getpass("LUKS passphrase (repeat): ")
    if first != second or not first:
        raise PartitionError("passphrases do not match or are empty")
    return first


def _disk_part(disk, number):
    base = os.path.basename(disk)
    sep = "p" if base[-1].isdigit() else ""
    return f"{disk}{sep}{number}"


def partition_disk(disk, schema, root, efi=None, luks_pass_file=None,
                   hooks=None, assume_yes=False):
    """Wipe, partition, format and mount disk at root."""
    if efi is None:
        efi = is_efi()
    if not efi:
        msg = ("no UEFI detected: installing in BIOS mode, "
               "EFI is recommended")
        if hooks is not None:
            hooks.warn(msg)
        else:
            print(f"warning: {msg}")
    luks = schema.startswith("luks-")
    require_tools()

    if not os.path.exists(disk):
        raise PartitionError(f"disk {disk} does not exist")
    if not assume_yes:
        answer = input(
            f"WIPE {disk} and install with schema '{schema}'? Type YES: "
        )
        if answer.strip() != "YES":
            raise PartitionError("aborted by user")

    plan = plan_partitions(schema, efi)
    boot_label, _boot_fs, _boot_mp = plan[0]

    _run(["parted", "-s", disk, "mklabel", "gpt"])
    if efi:
        _run(["parted", "-s", disk, "mkpart", "ESP", "fat32",
              "1MiB", ESP_SIZE, "set", "1", "esp", "on"])
        _run(["parted", "-s", disk, "mkpart", "root", "ext4",
              ESP_SIZE, "100%"])
    else:
        _run(["parted", "-s", disk, "mkpart", "bios-boot",
              "1MiB", "2MiB", "set", "1", "bios_grub", "on"])
        _run(["parted", "-s", disk, "mkpart", "root", "ext4",
              "2MiB", "100%"])
    _run(["sleep", "1"])
    _ = boot_label

    boot_part = _disk_part(disk, 1)
    root_part = _disk_part(disk, 2)

    if luks:
        passphrase = _read_luks_passphrase(luks_pass_file)
        _run(["cryptsetup", "luksFormat", "--batch-mode",
              "--key-file=-", root_part], input=passphrase.encode())
        _run(["cryptsetup", "open", "--key-file=-", root_part,
              LUKS_MAPPER_NAME], input=passphrase.encode())
        root_dev = f"/dev/mapper/{LUKS_MAPPER_NAME}"
    else:
        root_dev = root_part

    if efi:
        _run(["mkfs.fat", "-F32", "-n", "ESP", boot_part])

    if "ext4" in schema:
        _run(["mkfs.ext4", "-L", "nixos", root_dev])
        os.makedirs(root, exist_ok=True)
        _run(["mount", root_dev, root])
    else:
        _run(["mkfs.btrfs", "-L", "nixos", "-f", root_dev])
        os.makedirs(root, exist_ok=True)
        _run(["mount", root_dev, root])
        for subvol in ("@", "@home"):
            _run(["btrfs", "subvolume", "create",
                  os.path.join(root, subvol)])
        _run(["umount", root])
        _run(["mount", "-o", "subvol=@,compress=zstd,noatime",
              root_dev, root])
        os.makedirs(os.path.join(root, "home"), exist_ok=True)
        _run(["mount", "-o", "subvol=@home,compress=zstd,noatime",
              root_dev, os.path.join(root, "home")])

    if efi:
        os.makedirs(os.path.join(root, "boot"), exist_ok=True)
        _run(["mount", boot_part, os.path.join(root, "boot")])

    print(f"Partitioned {disk} ({schema}, {'EFI' if efi else 'BIOS'}) "
          f"and mounted at {root}")
    return efi
