#!/usr/bin/env python3
import getpass
import os
import shutil
import subprocess

SCHEMAS = ("ext4", "btrfs", "luks-ext4", "luks-btrfs",
           "btrfs-impermanence", "luks-btrfs-impermanence",
           "ext4-impermanence", "luks-ext4-impermanence")
DEFAULT_SCHEMA = "btrfs"
DEFAULT_IMPERMANENCE_SCHEMA = "btrfs-impermanence"

ESP_SIZE = "512MiB"
LUKS_MAPPER_NAME = "garuda-root"


class PartitionError(Exception):
    pass


CMD_PREFIX = []


def is_efi(path="/sys/firmware/efi"):
    return os.path.isdir(path)


def require_tools():
    tools = ["parted", "mkfs.fat", "mkfs.ext4", "mkfs.btrfs", "btrfs",
             "cryptsetup", "mount", "umount", "udevadm", "wipefs"]
    missing = [t for t in tools if shutil.which(t) is None]

    if missing:
        raise PartitionError(
            f"missing tools: {', '.join(missing)} (need parted, dosfstools, "
            "e2fsprogs, btrfs-progs, cryptsetup, util-linux)"
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


IMPERMANENCE_SUBVOLS = ("root", "nix", "persist")
IMPERMANENCE_MOUNTS = (
    ("root", ""),
    ("nix", "nix"),
    ("persist", "persist"),
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


VIRTUAL_DISK_PREFIXES = ("zram", "ram", "dm-", "md", "loop")


def schemas_for_features(features):
    if features and "impermanence" in features:
        return tuple(s for s in SCHEMAS if "impermanence" in s)

    return SCHEMAS


def default_schema_for_features(features):
    if features and "impermanence" in features:
        return DEFAULT_IMPERMANENCE_SCHEMA

    return DEFAULT_SCHEMA

def _parse_lsblk(data):
    import json

    disks = []

    for dev in json.loads(data).get("blockdevices", []):
        if dev.get("type") != "disk":
            continue

        name = dev["name"]

        if name.startswith(VIRTUAL_DISK_PREFIXES):
            continue

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


def _run(cmd, msg=None, **kwargs):
    if msg is not None:
        print(msg, flush=True)

    try:
        subprocess.run(CMD_PREFIX + cmd, check=True,
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                       text=True, **kwargs)
    except subprocess.CalledProcessError as e:
        if e.stdout:
            print(e.stdout, end="", flush=True)

        raise


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


def _read_luks_passphrase(pass_file=None, attempts=3, min_length=8):
    if pass_file:
        with open(pass_file) as f:
            passphrase = f.read().strip("\n")

        if not passphrase:
            raise PartitionError("LUKS passphrase file is empty")

        return passphrase

    last_error = "passphrases do not match or are empty"

    for attempt in range(max(1, attempts)):
        first = getpass.getpass("LUKS passphrase: ")
        second = getpass.getpass("LUKS passphrase (repeat): ")

        if first and first == second:
            if len(first) < min_length:
                print(f"warning: passphrase is short "
                      f"({len(first)} < {min_length} chars)",
                      flush=True)

            return first

        last_error = "passphrases do not match or are empty"
        remaining = attempts - attempt - 1

        if remaining > 0:
            print(f"error: {last_error} "
                  f"({remaining} attempt(s) left)", flush=True)

    raise PartitionError(last_error)


def _confirm_wipe(disk, schema, attempts=3):
    for attempt in range(max(1, attempts)):
        answer = input(
            f"WIPE {disk} and install with schema '{schema}'? Type YES: "
        ).strip()

        if answer.lower() == "yes":
            return

        if answer.lower() in ("n", "no", "q", "quit"):
            raise PartitionError("aborted by user")

        remaining = attempts - attempt - 1

        if remaining > 0:
            print(f"error: type YES to confirm "
                  f"({remaining} attempt(s) left)", flush=True)

    raise PartitionError("aborted by user")


def _cleanup_partial(root):
    for cmd in (["umount", "-R", root],
                ["cryptsetup", "close", LUKS_MAPPER_NAME]):
        try:
            subprocess.run(cmd, check=False,
                           stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL)
        except OSError:
            pass


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

    if luks:
        passphrase = _read_luks_passphrase(luks_pass_file)

    else:
        passphrase = None

    if not assume_yes:
        _confirm_wipe(disk, schema)

    plan = plan_partitions(schema, efi)
    boot_label, _boot_fs, _boot_mp = plan[0]

    _run(["parted", "-s", disk, "mklabel", "gpt"],
         msg=f"Creating partition table on {disk} ...")

    if efi:
        _run(["parted", "-s", disk, "mkpart", "ESP", "fat32",
              "1MiB", ESP_SIZE, "set", "1", "esp", "on"],
             msg="Creating EFI partition ...")
        _run(["parted", "-s", disk, "mkpart", "root", "ext4",
              ESP_SIZE, "100%"], msg="Creating root partition ...")

    else:
        _run(["parted", "-s", disk, "mkpart", "bios-boot",
              "1MiB", "2MiB", "set", "1", "bios_grub", "on"],
             msg="Creating BIOS boot partition ...")
        _run(["parted", "-s", disk, "mkpart", "root", "ext4",
              "2MiB", "100%"], msg="Creating root partition ...")

    _run(["udevadm", "settle"])

    _ = boot_label

    boot_part = _disk_part(disk, 1)
    root_part = _disk_part(disk, 2)
    _run(["wipefs", "-a", root_part])

    if efi:
        _run(["wipefs", "-a", boot_part])

    if luks:
        assert passphrase is not None
        _run(["cryptsetup", "luksFormat", "--batch-mode",
              "--key-file=-", root_part], input=passphrase,
             msg="Encrypting root partition ...")
        _run(["cryptsetup", "open", "--key-file=-", root_part,
              LUKS_MAPPER_NAME], input=passphrase,
             msg="Unlocking encrypted root ...")
        root_dev = f"/dev/mapper/{LUKS_MAPPER_NAME}"

    else:
        root_dev = root_part

    if efi:
        _run(["mkfs.fat", "-F32", "-n", "ESP", boot_part],
             msg="Formatting EFI partition ...")
        _run(["udevadm", "settle"])

    if "impermanence" in schema:
        os.makedirs(root, exist_ok=True)

        if "ext4" in schema:
            _run(["mkfs.ext4", "-L", "nixos", root_dev],
                 msg="Formatting root partition ...")
            _run(["udevadm", "settle"])
            _mount_ext4_impermanence(root_dev, root)

        else:
            _run(["mkfs.btrfs", "-L", "nixos", "-f", root_dev],
                 msg="Formatting root partition ...")
            _run(["udevadm", "settle"])
            _mount_btrfs_impermanence(root_dev, root)

    elif "ext4" in schema:
        _run(["mkfs.ext4", "-L", "nixos", root_dev],
             msg="Formatting root partition ...")
        _run(["udevadm", "settle"])
        os.makedirs(root, exist_ok=True)
        _run(["mount", root_dev, root])

    else:
        _run(["mkfs.btrfs", "-L", "nixos", "-f", root_dev],
             msg="Formatting root partition ...")
        _run(["udevadm", "settle"])
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
