#!/usr/bin/env python3
import atexit
import os
import subprocess
import sys
import tempfile

ENV_KEYS = ("GNS_INSTALLER_LIB", "GNS_FORCE", "GNS_EDITION", "GNS_FLAKE_REF",
            "GNS_VERSION", "GNS_SELF", "GNS_MNT_DIR", "GNS_BTRFS_UUID",
            "GNS_FROM_HOST", "GNS_INSTALLING", "PATH")


def ensure_root():
    if os.geteuid() != 0:
        carry = [f"{k}={os.environ[k]}" for k in ENV_KEYS if k in os.environ]
        os.execvp("sudo", ["sudo", "env"] + carry + [sys.argv[0]] + sys.argv[1:])


def run(cmd, **kwargs):
    subprocess.run(cmd, check=True, **kwargs)


def step(msg):
    if sys.stderr.isatty():
        line = f"\r\x1b[2K\033[1;32m»\033[0m {msg}\n"
    else:
        line = f"» {msg}\n"
    sys.stderr.write(line)
    sys.stderr.flush()


def btrfs_uuid():
    return subprocess.check_output(
        ["findmnt", "-n", "-o", "UUID", "/"], text=True).strip()


def ensure_subvolume(uuid):
    top = tempfile.mkdtemp(prefix="gns-top-", dir="/run/gns")
    try:
        run(["mount", f"UUID={uuid}", top])
        try:
            if not os.path.isdir(os.path.join(top, "@nix-subsystem")):
                step("Creating Garuda Nix Subsystem subvolume")
                run(["btrfs", "subvolume", "create",
                     os.path.join(top, "@nix-subsystem")])
        finally:
            subprocess.run(["umount", top], check=False)
    finally:
        os.rmdir(top)


def unmount_subsystem(mnt, remove=False):
    for target in (os.path.join(mnt, "nix"), mnt):
        r = subprocess.run(["umount", target], check=False,
                           stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL)

        if r.returncode != 0:
            subprocess.run(["umount", "-l", target], check=False,
                           stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL)
    if remove:
        try:
            os.rmdir(mnt)
        except OSError:
            pass


def mount_subsystem(uuid):
    mnt = tempfile.mkdtemp(prefix="gns-mnt-", dir="/run/gns")
    atexit.register(unmount_subsystem, mnt, True)
    run(["mount", "-o", "subvol=@nix-subsystem", f"UUID={uuid}", mnt])
    os.makedirs(os.path.join(mnt, "nix"), exist_ok=True)
    run(["mount", "-o", "subvol=@nix", f"UUID={uuid}",
         os.path.join(mnt, "nix")])
    return mnt


def prepare_dirs():
    os.makedirs("/var/tmp", exist_ok=True)
    os.environ.setdefault("TMPDIR", "/var/tmp")
    os.makedirs("/run/gns", exist_ok=True)


def git_commit(repo_dir, message, run=None):
    run = run or (
        lambda cmd: subprocess.check_output(
            cmd, stderr=subprocess.STDOUT, text=True)
    )
    if not os.path.isdir(os.path.join(repo_dir, ".git")):
        run(["git", "init", repo_dir])

    if not run(["git", "-C", repo_dir, "status", "--porcelain"]).strip():
        return

    run(["git", "-C", repo_dir, "add", "-A"])
    run(["git", "-C", repo_dir, "-c", "user.name=gns",
         "-c", "user.email=gns@localhost", "commit", "-m", message])
