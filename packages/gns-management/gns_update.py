#!/usr/bin/env python3
import grp
import json
import os
import pwd
import re
import subprocess
import sys


def repo_path():
    env = os.environ.get("GNS_INSTALLER_LIB")
    if env:
        return env
    return os.path.normpath(
        os.path.join(
            os.path.dirname(os.path.abspath(__file__)),
            "..",
            "calamares-nixos-extensions",
            "installer-lib",
        )
    )


sys.path.insert(0, repo_path())
import garuda_progress as gprog
import garuda_subsystem as gs

GRUB_ENTRY = """#!/bin/sh
exec tail -n +3 $0

menuentry 'Garuda Linux Nix Subsystem' --class garuda --class gnu-linux --class gnu --class os {
    configfile /@nix-subsystem/boot/grub/grub.cfg
}
"""

LOCALE_RE = re.compile(r"^[A-Za-z_]+=.+$")


class UpdateError(Exception):
    pass


def detect_virt():
    try:
        out = subprocess.check_output(["systemd-detect-virt"], text=True).strip()
    except (OSError, subprocess.CalledProcessError):
        return "none"
    return out or "none"


def shadow_hash(user):
    try:
        with open("/etc/shadow") as f:
            for line in f:
                if line.startswith(user + ":"):
                    return line.rstrip("\n").split(":")[1]
    except OSError:
        pass
    return ""


def groups_of(user, gid):
    groups = {g.gr_name for g in grp.getgrall() if user in g.gr_mem}
    try:
        groups.add(grp.getgrgid(gid).gr_name)
    except KeyError:
        pass
    return groups


def collect_host():
    host = {}
    users = []
    for entry in pwd.getpwall():
        if entry.pw_uid >= 1000 and entry.pw_dir.startswith("/home/"):
            admin = bool(groups_of(entry.pw_name, entry.pw_gid) & {"sudo", "wheel"})
            users.append(
                {
                    "name": entry.pw_name,
                    "uid": entry.pw_uid,
                    "hashed_password": shadow_hash(entry.pw_name),
                    "fullname": entry.pw_gecos.split(",")[0].strip(),
                    "home": entry.pw_dir,
                    "wheel": admin,
                }
            )
    if users:
        host["users"] = users
    root_hash = shadow_hash("root")
    if root_hash:
        host["hashed_root_password"] = root_hash
    try:
        with open("/etc/locale.conf") as f:
            locale = dict(
                line.rstrip("\n").split("=", 1)
                for line in f
                if LOCALE_RE.match(line.rstrip("\n"))
            )
    except OSError:
        locale = {}
    if locale:
        host["locale"] = locale
    try:
        with open("/etc/vconsole.conf") as f:
            keymap = next(
                (
                    line.rstrip("\n").split("=", 1)[1]
                    for line in f
                    if line.startswith("KEYMAP=")
                ),
                "",
            )
    except OSError:
        keymap = ""
    if keymap:
        host["keymap"] = keymap
    try:
        with open("/etc/timezone") as f:
            timezone = f.read().strip()
    except OSError:
        timezone = ""
    if timezone:
        host["timezone"] = timezone
    try:
        installed = subprocess.check_output(
            ["pacman", "-Qq", "garuda-nvidia-config", "garuda-nvidia-prime-config"],
            text=True,
            stderr=subprocess.DEVNULL,
        ).split()
    except (OSError, subprocess.CalledProcessError):
        installed = []
    if "garuda-nvidia-prime-config" in installed:
        host.setdefault("hardware", {})["nvidia"] = "prime"
    elif "garuda-nvidia-config" in installed:
        host.setdefault("hardware", {})["nvidia"] = "nvidia"
    return host


def apply_managed(config, host, uuid, virt, version):
    config = dict(config)
    v2 = dict(config.get("v2", {}))
    if (config.get("version") or 0) < 2:
        if host is None:
            raise UpdateError(
                "Garuda Nix Subsystem must be updated from the "
                'host system. Run "garuda-nix-subsystem update"'
            )
        config.pop("v1", None)
        v2["subsystem"] = True
    if host is not None:
        v2.pop("host", None)
        if host:
            v2["host"] = host
    v2.pop("auto", None)
    v2["auto"] = {"uuid": uuid, "hardware": {"virt": virt}}
    config["v2"] = v2
    config["version"] = int(version)
    return config


def build_install_cmd(mnt, hostname):
    return [
        "nixos-install",
        "-j",
        "auto",
        "--no-root-password",
        "--root",
        mnt,
        "--flake",
        f"{mnt}/etc/nixos#{hostname}",
        "--log-format",
        "internal-json",
    ]


def build_rebuild_cmd(mnt, hostname):
    return [
        "nh",
        "os",
        "boot",
        "-R",
        "--no-nom",
        "--log-format",
        "internal-json",
        "-j",
        "auto",
        "-H",
        hostname,
        f"{mnt}/etc/nixos",
    ]


def write_grub_entry():
    with open("/etc/grub.d/25-garudanix", "w") as f:
        f.write(GRUB_ENTRY)
    os.chmod("/etc/grub.d/25-garudanix", 0o755)
    gs.run(["/usr/bin/update-grub"])


def main(argv=None):
    installing = os.environ.get("GNS_INSTALLING", "false") == "true"
    from_host = installing or os.environ.get("GNS_FROM_HOST", "false") == "true"
    gs.ensure_root()
    gs.prepare_dirs()

    uuid = os.environ.get("GNS_BTRFS_UUID") or gs.btrfs_uuid()
    mnt = None
    if from_host:
        reuse = os.environ.get("GNS_MNT_DIR", "")
        if (
            reuse
            and os.path.ismount(reuse)
            and os.path.ismount(os.path.join(reuse, "nix"))
        ):
            mnt = reuse
        else:
            gs.step("Mounting Garuda Nix Subsystem subvolumes")
            gs.ensure_subvolume(uuid)
            mnt = gs.mount_subsystem(uuid)
    mnt = mnt or os.environ.get("GNS_MNT_DIR", "")

    managed_path = os.path.join(mnt, "etc/nixos/garuda-managed.json")
    if not os.path.exists(managed_path):
        print(
            "error: Garuda Nix Subsystem is not configured for automatic "
            "management. (Missing garuda-managed.json)",
            file=sys.stderr,
        )
        return 1
    with open(managed_path) as f:
        config = json.load(f)
    hostname = config.get("hostname", "")

    gs.step("Configuring Garuda Nix Subsystem")
    try:
        config = apply_managed(
            config,
            collect_host() if from_host else None,
            uuid,
            detect_virt(),
            os.environ.get("GNS_VERSION") or config.get("version", 2),
        )
    except UpdateError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    with open(managed_path, "w") as f:
        json.dump(config, f, indent=2)
        f.write("\n")

    gs.step(
        "Installing Garuda Nix Subsystem 🍵"
        if installing
        else "Updating Garuda Nix Subsystem 🍵"
    )
    gns_self = os.environ.get("GNS_SELF", "")
    if not gns_self:
        print("error: GNS_SELF is not set", file=sys.stderr)
        return 1
    try:
        subprocess.run(
            [
                "nix",
                "flake",
                "update",
                "--flake",
                f"{mnt}/etc/nixos",
                "--override-input",
                "garuda",
                gns_self,
            ],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as e:
        print(e.stdout, end="")
        print(e.stderr, end="", file=sys.stderr)
        return e.returncode
    if from_host:
        rc = gprog.run(build_install_cmd(mnt, hostname))
    elif not installing:
        rc = gprog.run(build_rebuild_cmd(mnt, hostname))
    else:
        print("error: ..What?", file=sys.stderr)
        return 1
    if rc != 0:
        return rc

    gs.git_commit(os.path.join(mnt, "etc/nixos"), "gns-update")

    if from_host:
        gs.step("Unmounting Garuda Nix Subsystem subvolumes")
        gs.unmount_subsystem(mnt, remove=True)
        write_grub_entry()
    return 0


if __name__ == "__main__":
    sys.exit(main())
