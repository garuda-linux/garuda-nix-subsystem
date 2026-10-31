#!/usr/bin/env python3
"""garuda-update as fetched from the stable branch, by Nix or by git clone."""

import argparse
import datetime
import fcntl
import os
import pty
import re
import shutil
import subprocess
import sys
import termios
import threading

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import fixes

REPO = "https://gitlab.com/garuda-linux/garuda-nix.git"
LOG_FILE = "/var/log/garuda/garuda-update"
MANAGED = "/etc/nixos/garuda-managed.json"
SEQUENCE_FILE = os.path.join(fixes.STATE_DIR, "intervention_sequence")
SEQUENCE_RE = re.compile(r"^INTERVENTION_SEQUENCE=([0-9]+)$", re.MULTILINE)
ANSI_RE = re.compile(rb"\x1b\[[0-9;?]*[a-zA-Z]")
GIT_ID = ["-c", "user.name=garuda-update", "-c", "user.email=garuda-update@localhost"]
QUIET = {"stdout": subprocess.DEVNULL, "stderr": subprocess.DEVNULL}


def step(msg):
    prefix = "\033[1;32m»\033[0m" if sys.stderr.isatty() else "»"
    print(f"{prefix} {msg}", file=sys.stderr, flush=True)


def sibling(*parts):
    return os.path.normpath(os.path.join(HERE, "..", *parts))


def detect_context(environ=os.environ, exists=os.path.exists):
    if environ.get("GNS_FROM_HOST") == "true":
        return "host"

    return "managed" if exists(MANAGED) else "flake"


def read_sequence(root):
    try:
        with open(os.path.join(root, SEQUENCE_FILE)) as f:
            match = SEQUENCE_RE.search(f.read())
    except OSError:
        return 0

    # A broken file reruns all fixes, their checks keep that safe
    return int(match.group(1)) if match else 0


def write_sequence(root, sequence):
    path = os.path.join(root, SEQUENCE_FILE)
    os.makedirs(os.path.dirname(path), exist_ok=True)

    with open(path, "w") as f:
        f.write(f"# Written by garuda-update\nINTERVENTION_SEQUENCE={sequence}\n")


def installer_lib(environ=os.environ):
    return environ.get("GNS_INSTALLER_LIB") or sibling("garuda-installer-lib")


def clone_env(environ, repo=None, run=subprocess.check_output):
    """Environment of gns_update when it runs from a git clone."""
    repo = repo or sibling("..")
    url = environ.get("GARUDA_UPDATE_REPO") or REPO
    rev = run(["git", "-C", repo, "rev-parse", "HEAD"], text=True).strip()
    ref = run(["git", "-C", repo, "rev-parse", "--abbrev-ref", "HEAD"], text=True)

    with open(os.path.join(repo, "lib", "garuda-lib.nix")) as f:
        version = re.search(r"^\s*version = ([0-9]+);", f.read(), re.MULTILINE)

    env = dict(
        environ,
        GNS_INSTALLER_LIB=installer_lib(environ),
        GNS_SELF=f"git+{url}?ref={ref.strip()}&rev={rev}",
    )

    # Without it gns_update keeps the version of garuda-managed.json
    if version:
        env["GNS_VERSION"] = version.group(1)

    return env


def gns_backend(environ, which=shutil.which):
    """Command and environment of the managed and subsystem update."""
    if environ.get("GNS_UPDATE_BIN"):
        return [environ["GNS_UPDATE_BIN"]], dict(environ)

    cmd = [sys.executable, sibling("gns-management", "gns_update.py")]

    if not (which("nh") and which("nixos-install")):
        tools = ["nixpkgs#nh", "nixpkgs#nixos-install-tools"]
        cmd = ["nix", "shell", *tools, "-c", *cmd]

    return cmd, clone_env(environ)


def git_commit(repo, files, message, call=subprocess.call):
    if files and os.path.isdir(os.path.join(repo, ".git")):
        git = ["git", "-C", repo]

        call([*git, "add", "--", *files], **QUIET)
        call(
            [*git, *GIT_ID, "commit", "--no-verify", "-qm", message, "--", *files],
            **QUIET,
        )


def flake_backend(flake, call=subprocess.call):
    step("Updating flake inputs 🍵")
    rc = call(["nix", "flake", "update", "--flake", flake])

    if rc == 0:
        step("Rebuilding system 🍵")
        rc = call(["nh", "os", "switch", "--bypass-root-check", flake])

    if rc == 0:
        today = datetime.datetime.now().astimezone().date()
        git_commit(flake, ["flake.lock"], f"chore(flake.lock): {today}", call)

    return rc


def inhibit(environ=os.environ):
    """Re-exec under systemd-inhibit to block sleep during the update."""
    tool = shutil.which("systemd-inhibit")

    if (
        tool
        and "GARUDA_SLEEP_INHIBIT" not in environ
        and os.path.isdir("/run/systemd/system")
    ):
        args = ["--who=Garuda Update", "--why=Performing a system update"]

        os.execve(
            tool,
            [tool, *args, sys.executable, *sys.argv],
            dict(environ, GARUDA_SLEEP_INHIBIT="1"),
        )


def clean_log_line(line):
    return ANSI_RE.sub(b"", line.rstrip(b"\r").split(b"\r")[-1]).rstrip()


class Log:
    """Tee stdout and stderr into the log file."""

    def __init__(self, path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        self.file = open(path, "ab")  # noqa: SIM115
        now = datetime.datetime.now().astimezone().strftime("%Y-%m-%d %R %Z")
        self.file.write(f"\n>-<->-< garuda-update at {now}\n\n".encode())

        # Point stdout and stderr at a pty or pipe that _pump copies to the log
        self.saved = (os.dup(1), os.dup(2))
        master, slave = self._pty() if os.isatty(1) else os.pipe()
        os.dup2(slave, 1)
        os.dup2(slave, 2)
        os.close(slave)

        self.thread = threading.Thread(target=self._pump, args=(master,), daemon=True)
        self.thread.start()

    @staticmethod
    def _pty():
        """A pty of the terminal's size, so progress output stays interactive."""
        master, slave = pty.openpty()
        size = fcntl.ioctl(1, termios.TIOCGWINSZ, b"\0" * 8)
        fcntl.ioctl(slave, termios.TIOCSWINSZ, size)

        attrs = termios.tcgetattr(slave)
        attrs[1] &= ~termios.ONLCR
        termios.tcsetattr(slave, termios.TCSANOW, attrs)

        return master, slave

    def _pump(self, master):
        rest = b""

        while True:
            try:
                data = os.read(master, 4096)
            except OSError:
                break

            if not data:
                break

            os.write(self.saved[0], data)

            *lines, rest = (rest + data).split(b"\n")
            self.file.writelines(clean_log_line(line) + b"\n" for line in lines)
            self.file.flush()

    def close(self):
        sys.stdout.flush()
        sys.stderr.flush()

        os.dup2(self.saved[0], 1)
        os.dup2(self.saved[1], 2)

        self.thread.join(timeout=5)
        self.file.close()


def mount_host(environ):
    """Mount the subsystem and keep it mounted for the fixes."""
    sys.path.insert(0, installer_lib(environ))
    import garuda_subsystem as gs

    gs.prepare_dirs()
    uuid = environ.get("GNS_BTRFS_UUID") or gs.btrfs_uuid()

    step("Mounting Garuda Nix Subsystem subvolumes")
    gs.ensure_subvolume(uuid)
    mnt = gs.mount_subsystem(uuid)

    environ.update(GNS_MNT_DIR=mnt, GNS_BTRFS_UUID=uuid, GNS_KEEP_MOUNT="true")

    return mnt


def print_notices(notices):
    if notices:
        lines = "\n".join(f"- {notice}" for notice in notices)

        print(f"\n\033[1;32mUpdate notices:\n\033[1;34m{lines}\033[0m", file=sys.stderr)


def update(
    context,
    flake,
    environ=os.environ,
    call=subprocess.call,
    mount=mount_host,
    root="/",
    backend=gns_backend,
):
    if context == "host":
        root = mount(environ)

    if context != "flake":
        flake = os.path.join(root, "etc/nixos")

        # Before the fixes, so a failure here leaves the system untouched
        try:
            cmd, backend_env = backend(environ)
        except (OSError, subprocess.CalledProcessError) as e:
            print(
                f"\033[1;31mError: Unable to prepare the update ({e}). "
                "The system was not updated. ❌\033[0m",
                file=sys.stderr,
            )
            return 1

    env = fixes.Env(context=context, root=root, flake=flake)
    sequence = read_sequence(root)

    ok = fixes.run_phase(env, "pre", sequence, log=step)

    if context == "flake":
        git_commit(flake, env.touched, "fix: apply garuda-update fixes", call)
        rc = flake_backend(flake, call)
    else:
        rc = call(cmd, env=backend_env)

    if rc == 0:
        ok = fixes.run_phase(env, "post", sequence, log=step) and ok

        if ok and sequence != fixes.CURRENT_SEQUENCE:
            write_sequence(root, fixes.CURRENT_SEQUENCE)

        print("\n\033[1;32mSystem updated! 🐧\033[0m", file=sys.stderr)

    print_notices(env.notices)

    return rc


def main(argv=None):
    parser = argparse.ArgumentParser(prog="garuda-update")
    parser.add_argument(
        "--flake",
        default=os.environ.get("GARUDA_FLAKE", "/etc/nixos"),
        help="flake to update on systems without garuda-managed.json",
    )
    args = parser.parse_args(argv)

    if os.geteuid() != 0:
        print("error: garuda-update must run as root", file=sys.stderr)
        return 1

    if os.environ.get("GNS_INSTALLING") == "true":
        cmd, env = gns_backend(os.environ)

        return subprocess.call(cmd, env=env)

    inhibit()
    log = Log(LOG_FILE)

    try:
        return update(detect_context(), os.path.abspath(args.flake))
    finally:
        log.close()


if __name__ == "__main__":
    sys.exit(main())
