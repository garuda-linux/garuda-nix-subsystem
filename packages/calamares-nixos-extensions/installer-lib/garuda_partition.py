#!/usr/bin/env python3
import getpass
import os
import shutil
import subprocess

SCHEMAS = ("ext4", "btrfs", "luks-ext4", "luks-btrfs",
           "btrfs-impermanence", "luks-btrfs-impermanence",
           "ext4-impermanence", "luks-ext4-impermanence")
DEFAULT_SCHEMA = "btrfs"

ESP_SIZE = "512MiB"
LUKS_MAPPER_NAME = "garuda-root"


class PartitionError(Exception):
    pass


CMD_PREFIX = []


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


def is_tmpfs_root(schema):
    return schema is not None and "impermanence" in schema and "ext4" in schema


def plan_partitions(schema, efi=True):
    if schema not in SCHEMAS:
        raise PartitionError(
            f"unknown schema {schema!r}, choose from: {', '.join(SCHEMAS)}"
        )
    fs = "ext4" if "ext4" in schema else "btrfs"
    mountpoint = "/nix" if "impermanence" in schema else "/"
    boot = ("esp", "vfat", "/boot") if efi else ("bios-boot", None, None)
    return [boot, ("root", fs, mountpoint)]


IMPERMANENCE_SUBVOLS = ("root", "home", "nix", "persist", "log")
IMPERMANENCE_MOUNTS = (
    ("root", ""),
    ("home", "home"),
    ("nix", "nix"),
    ("persist", "persist"),
    ("log", "var/log"),
)

GARUDA_SUBVOLS = (
    ("@", ""),
    ("@home", "home"),
    ("@root", "root"),
    ("@srv", "srv"),
    ("@nix", "nix"),
    ("@cache", "var/cache"),
    ("@log", "var/log"),
    ("@tmp", "var/tmp"),
)


def _parse_lsblk(data):
    import json
    disks = []
    for dev in json.loads(data).get("blockdevices", []):
        if dev.get("type") != "disk":
            continue
        name = dev["name"]
        size = dev.get("size") or "?"
        model = (dev.get("model") or "").strip()
        label = f"{name}  {size}  {model}".rstrip()
        disks.append((f"/dev/{name}", label))
    return disks


def list_disks():
    out = subprocess.check_output(
        ["lsblk", "-J", "-o", "NAME,SIZE,MODEL,TYPE", "-d", "-e", "7,11"],
        text=True,
    )
    return _parse_lsblk(out)


def _run(cmd, **kwargs):
    subprocess.check_call(CMD_PREFIX + cmd, **kwargs)


def _mount_ext4_impermanence(root_dev, root):
    nix_dir = os.path.join(root, "nix")
    persist_dir = os.path.join(root, "persist")
    os.makedirs(nix_dir, exist_ok=True)
    _run(["mount", root_dev, nix_dir])
    os.makedirs(os.path.join(nix_dir, "persist"), exist_ok=True)
    os.makedirs(persist_dir, exist_ok=True)
    _run(["mount", "--bind", os.path.join(nix_dir, "persist"),
          persist_dir])


def _mount_btrfs_impermanence(root_dev, root):
    _run(["mount", root_dev, root])
    for subvol in IMPERMANENCE_SUBVOLS:
        _run(["btrfs", "subvolume", "create",
              os.path.join(root, subvol)])
    _run(["btrfs", "subvolume", "snapshot", "-r",
          os.path.join(root, "root"), os.path.join(root, "root-blank")])
    _run(["umount", root])
    for subvol, rel in IMPERMANENCE_MOUNTS:
        target = os.path.join(root, rel)
        os.makedirs(target, exist_ok=True)
        _run(["mount", "-o", f"subvol={subvol},compress=zstd,noatime",
              root_dev, target])


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


def parent_disk(device):
    import re
    return re.sub(r"p?\d+$", "", device)


def mounted_layout(schema):
    if "impermanence" in schema:
        if "ext4" in schema:
            return [("/nix", "ext4")]
        mounts = IMPERMANENCE_MOUNTS
    elif "ext4" in schema:
        return [("/", "ext4")]
    else:
        mounts = GARUDA_SUBVOLS
    fs = "ext4" if "ext4" in schema else "btrfs"
    return [("/" + rel if rel else "/", fs) for _, rel in mounts]


def partition_disk(disk, schema, root, efi=None, luks_pass_file=None,
                   hooks=None, assume_yes=False):
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

    if "impermanence" in schema:
        os.makedirs(root, exist_ok=True)
        if "ext4" in schema:
            _run(["mkfs.ext4", "-L", "nixos", root_dev])
            _mount_ext4_impermanence(root_dev, root)
        else:
            _run(["mkfs.btrfs", "-L", "nixos", "-f", root_dev])
            _mount_btrfs_impermanence(root_dev, root)
    elif "ext4" in schema:
        _run(["mkfs.ext4", "-L", "nixos", root_dev])
        os.makedirs(root, exist_ok=True)
        _run(["mount", root_dev, root])
    else:
        _run(["mkfs.btrfs", "-L", "nixos", "-f", root_dev])
        os.makedirs(root, exist_ok=True)
        _run(["mount", root_dev, root])
        for subvol, _rel in GARUDA_SUBVOLS:
            _run(["btrfs", "subvolume", "create",
                  os.path.join(root, subvol)])
        _run(["umount", root])
        for subvol, rel in GARUDA_SUBVOLS:
            target = os.path.join(root, rel)
            os.makedirs(target, exist_ok=True)
            _run(["mount", "-o", f"subvol={subvol},compress=zstd,noatime",
                  root_dev, target])

    if efi:
        os.makedirs(os.path.join(root, "boot"), exist_ok=True)
        _run(["mount", boot_part, os.path.join(root, "boot")])

    print(f"Partitioned {disk} ({schema}, {'EFI' if efi else 'BIOS'}) "
          f"and mounted at {root}")
    return efi
