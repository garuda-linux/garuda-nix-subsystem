#!/usr/bin/env python3
import gettext
import json
import os
import subprocess
import sys

import libcalamares

_ = gettext.translation(
    "calamares-python",
    localedir=libcalamares.utils.gettext_path(),
    languages=libcalamares.utils.gettext_languages(),
    fallback=True,
).gettext

sys.path.insert(
    0,
    os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "..", "installer-lib"
    ),
)
import garuda_template as gt


class CalamaresHooks(gt.Hooks):
    """Route side effects through Calamares (pkexec, target writes)."""

    def run(self, cmd):
        if cmd[0] == "nixos-facter":
            cmd = ["pkexec"] + cmd
        return subprocess.check_output(cmd, stderr=subprocess.STDOUT)

    def warn(self, msg):
        libcalamares.utils.warning(msg)

    def write_file(self, path, text):
        libcalamares.utils.host_env_process_output(
            ["cp", "/dev/stdin", path],
            None,
            text,
        )


def env_is_set(name):
    envValue = os.environ.get(name)
    return not (envValue is None or envValue == "")


def generateProxyStrings():
    proxyEnv = []
    if env_is_set("http_proxy"):
        proxyEnv.append(f"http_proxy={os.environ.get('http_proxy')}")
    if env_is_set("https_proxy"):
        proxyEnv.append(f"https_proxy={os.environ.get('https_proxy')}")
    if env_is_set("HTTP_PROXY"):
        proxyEnv.append(f"HTTP_PROXY={os.environ.get('HTTP_PROXY')}")
    if env_is_set("HTTPS_PROXY"):
        proxyEnv.append(f"HTTPS_PROXY={os.environ.get('HTTPS_PROXY')}")

    if len(proxyEnv) > 0:
        proxyEnv.insert(0, "env")

    return proxyEnv


def pretty_name():
    return _("Installing NixOS.")


status = pretty_name()


def pretty_status_message():
    return status


# nix internal-json activity/result types
_ACT_COPY_PATH = 100
_ACT_COPY_PATHS = 103
_ACT_BUILDS = 104
_RES_PROGRESS = 105


class NixProgress:
    """Parse nix internal-json output and track build/copy progress."""

    def __init__(self):
        self._builds_done = 0
        self._builds_expected = 0
        self._copies_done = 0
        self._copies_expected = 0
        self._per_act_progress = {}
        self._copy_bytes = {}
        self._activities = {}
        self.fraction = 0.0
        self._floor = 0.0
        self._floor_done = 0
        self.log_messages = []

    def handle(self, line):
        """Process one line. Returns True for @nix lines, False for plain text."""
        line = line.strip()
        if not line:
            return True
        if not line.startswith("@nix "):
            return False
        try:
            msg = json.loads(line[5:])
        except (json.JSONDecodeError, ValueError):
            return False

        action = msg.get("action")
        if action == "start":
            self._on_start(msg)
        elif action == "stop":
            self._on_stop(msg)
        elif action == "result":
            self._on_result(msg)
        elif action == "msg":
            level = msg.get("level", 0)
            text = msg.get("msg", "")
            if level <= 1 and text:
                self.log_messages.append(text)

        self._update()
        return True

    def _on_start(self, msg):
        act_id = msg["id"]
        act_type = msg.get("type", 0)
        self._activities[act_id] = act_type
        text = msg.get("text", "")
        if text and msg.get("level", 5) <= 3:
            self.log_messages.append(text)

    def _on_stop(self, msg):
        act_id = msg["id"]
        self._activities.pop(act_id, None)
        self._copy_bytes.pop(act_id, None)

    def _on_result(self, msg):
        act_id = msg["id"]
        res_type = msg.get("type", 0)
        fields = msg.get("fields", [])
        act_type = self._activities.get(act_id, 0)

        if res_type != _RES_PROGRESS or len(fields) < 2:
            return
        if act_type == _ACT_BUILDS:
            self._per_act_progress[(act_type, act_id)] = (
                "builds",
                fields[0],
                fields[1],
            )
            self._recompute_counts()
        elif act_type == _ACT_COPY_PATHS:
            self._per_act_progress[(act_type, act_id)] = (
                "copies",
                fields[0],
                fields[1],
            )
            self._recompute_counts()
        elif act_type == _ACT_COPY_PATH:
            self._copy_bytes[act_id] = (fields[0], max(fields[1], 1))

    def _update(self):
        count_total = self._builds_expected + self._copies_expected
        count_done = self._builds_done + self._copies_done
        if count_total <= 0:
            return

        # Prevents the channel copy (1 path) from dominating the
        # entire progress bar before the main build starts.
        effective_total = max(count_total, 3)
        count_frac = count_done / effective_total

        # large single-path copies move the bar.
        total_bytes = sum(t for _, t in self._copy_bytes.values())
        done_bytes = sum(d for d, _ in self._copy_bytes.values())
        if total_bytes > 0:
            byte_sub = done_bytes / total_bytes
            step = len(self._copy_bytes) / effective_total
            raw = count_frac + byte_sub * step
        else:
            raw = count_frac
        raw = max(0.0, min(1.0, raw))

        # When the denominator grows (e.g. main build discovers hundreds
        # of new paths), remap remaining work into remaining bar space.
        if raw >= self._floor:
            self._floor = raw
            self._floor_done = count_done
        else:
            new_items = count_done - self._floor_done
            remaining = effective_total - self._floor_done
            if remaining > 0 and new_items >= 0:
                raw = self._floor + (new_items / remaining) * (1.0 - self._floor)
            else:
                raw = self._floor
            raw = max(0.0, min(1.0, raw))
            if raw > self._floor:
                self._floor = raw
                self._floor_done = count_done

        self.fraction = raw

    def _recompute_counts(self):
        bd = be = cd = ce = 0
        for kind, done, expected in self._per_act_progress.values():
            if kind == "builds":
                bd += done
                be += expected
            else:
                cd += done
                ce += expected
        self._builds_done = bd
        self._builds_expected = be
        self._copies_done = cd
        self._copies_expected = ce


def run():
    """NixOS Configuration (Garuda Nix flake)."""

    INSTALL_PROGRESS_START = 0.1
    INSTALL_PROGRESS_END = 1.0

    global status
    status = _("Configuring NixOS")
    libcalamares.job.setprogress(0.01)

    gs = libcalamares.globalstorage
    hooks = CalamaresHooks()

    # Setup variables
    root_mount_point = gs.value("rootMountPoint")
    nixos_dir = os.path.join(root_mount_point, "etc/nixos")
    fw_type = gs.value("firmwareType")
    bootdev = (
        "nodev"
        if gs.value("bootLoader") is None
        else gs.value("bootLoader")["installPath"]
    )

    hostname = gs.value("hostname") or "nixos"
    username = gs.value("username") or "garuda"
    partitions = gs.value("partitions") or []

    # Garuda Nix edition and features. The edition picker
    # (packagechooser.conf) writes GlobalStorage key
    # "packagechooser_packagechooser".
    features = []
    preset = None
    for op in gs.value("packageOperations") or []:
        if "netinstall" not in op.get("source", ""):
            continue
        for key in ("install", "try_install"):
            for pkg in op.get(key) or []:
                name = (
                    pkg.get("package", pkg.get("name"))
                    if isinstance(pkg, dict)
                    else pkg
                )
                if not isinstance(name, str):
                    continue
                if name.startswith("garuda-feature-"):
                    feature = name.removeprefix("garuda-feature-")
                    if feature in gt.GARUDA_FEATURES and feature not in features:
                        features.append(feature)
                elif name.startswith("garuda-preset-"):
                    candidate = name.removeprefix("garuda-preset-")
                    if candidate in gt.GARUDA_PRESETS and preset is None:
                        preset = candidate

    # Setup encrypted swap devices. nixos-generate-config doesn't seem to notice them.
    encrypted_swap = []
    for part in partitions:
        if (
            part.get("claimed") is True
            and part.get("fsName") in ("luks", "luks2")
            and part.get("device") is not None
            and part.get("fs") == "linuxswap"
        ):
            encrypted_swap.append(
                {"mapper": part["luksMapperName"], "uuid": part["uuid"]}
            )

    # Check partitions
    root_is_btrfs = False
    root_is_encrypted = False
    boot_is_encrypted = False
    boot_is_partition = False

    for part in partitions:
        if part.get("mountPoint") == "/":
            root_is_btrfs = part.get("fs") == "btrfs"
            root_is_encrypted = part.get("fsName") in ["luks", "luks2"]
        elif part.get("mountPoint") == "/boot":
            boot_is_partition = True
            boot_is_encrypted = part.get("fsName") in ["luks", "luks2"]

    # Setup keys in /boot/crypto_keyfile if using BIOS and Grub cryptodisk
    cryptodisk = False
    if fw_type != "efi" and (
        (boot_is_partition and boot_is_encrypted)
        or (root_is_encrypted and not boot_is_partition)
    ):
        cryptodisk = True
        status = _("Setting up LUKS")
        libcalamares.job.setprogress(0.02)
        try:
            libcalamares.utils.host_env_process_output(
                ["mkdir", "-p", root_mount_point + "/boot"], None
            )
            libcalamares.utils.host_env_process_output(
                ["chmod", "0700", root_mount_point + "/boot"], None
            )
            # Create /boot/crypto_keyfile.bin
            libcalamares.utils.host_env_process_output(
                [
                    "dd",
                    "bs=512",
                    "count=4",
                    "if=/dev/random",
                    "of=" + root_mount_point + "/boot/crypto_keyfile.bin",
                    "iflag=fullblock",
                ],
                None,
            )
            libcalamares.utils.host_env_process_output(
                ["chmod", "600", root_mount_point + "/boot/crypto_keyfile.bin"], None
            )
        except subprocess.CalledProcessError:
            libcalamares.utils.error("Failed to create /boot/crypto_keyfile.bin")

    status = _("Configuring Garuda Nix")
    libcalamares.job.setprogress(0.03)

    timezone = None
    if gs.value("locationRegion") is not None and gs.value("locationZone") is not None:
        timezone = f"{gs.value('locationRegion')}/{gs.value('locationZone')}"

    locale = None
    extra_locale = {}
    if gs.value("localeConf") is not None:
        localeconf = dict(gs.value("localeConf"))
        locale = (localeconf.get("LANG") or "").split("/")[0] or None
        locales = set(localeconf.values())
        if len(locales) != 1 or next(iter(locales)) != locale:
            extra_locale = {
                key: value.split("/")[0] for key, value in localeconf.items()
            }

    xkb_layout = gs.value("keyboardLayout")
    xkb_variant = gs.value("keyboardVariant")
    vconsole = None
    if xkb_layout is not None and xkb_variant is not None:
        if gs.value("keyboardVConsoleKeymap") is not None:
            try:
                subprocess.check_output(
                    ["pkexec", "loadkeys", gs.value("keyboardVConsoleKeymap").strip()],
                    stderr=subprocess.STDOUT,
                )
                vconsole = gs.value("keyboardVConsoleKeymap").strip()
            except subprocess.CalledProcessError as e:
                libcalamares.utils.error(f"loadkeys: {e.output}")
                libcalamares.utils.error(
                    f"Setting vconsole keymap to {gs.value('keyboardVConsoleKeymap').strip()} will fail, using default"
                )
        else:
            try:
                with open(
                    "/run/current-system/sw/share/systemd/kbd-model-map", "r"
                ) as kbdmodelmap:
                    kbd = kbdmodelmap.readlines()
            except OSError:
                kbd = []
            out = []
            for line in kbd:
                if line.startswith("#"):
                    continue
                out.append(line.split())
            find = []
            for row in out:
                if len(row) > 1 and gs.value("keyboardLayout") == row[1]:
                    find.append(row)
            if find != []:
                vconsole = find[0][0]
            else:
                vconsole = ""
            if gs.value("keyboardVariant") is not None:
                variant = gs.value("keyboardVariant")
            else:
                variant = "-"
            # Find rows with same variant
            for row in find:
                if len(row) > 3 and variant in row[3]:
                    vconsole = row[0]
                    break
                # If none found set to "us"
            if vconsole != "" and vconsole != "us" and vconsole is not None:
                try:
                    subprocess.check_output(
                        ["pkexec", "loadkeys", vconsole], stderr=subprocess.STDOUT
                    )
                except subprocess.CalledProcessError as e:
                    libcalamares.utils.error(f"loadkeys: {e.output}")
                    libcalamares.utils.error(f"vconsole value: {vconsole}")
                    libcalamares.utils.error(
                        f"Setting vconsole keymap to {gs.value('keyboardVConsoleKeymap')} will fail, using default"
                    )
                    vconsole = None

    try:
        nixosversion = (
            ".".join(
                subprocess.check_output(["nixos-version"], text=True).split(".")[:2]
            )[:5]
            or "26.11"
        )
    except (subprocess.CalledProcessError, OSError):
        nixosversion = "26.11"

    if fw_type == "efi":
        bootloader, grub_device = "systemd-boot", None
    elif bootdev != "nodev":
        bootloader, grub_device = "grub", bootdev
    else:
        bootloader, grub_device = "none", None

    picked_edition = gs.value("packagechooser_packagechooser")
    opts = gt.InstallOpts(
        edition=picked_edition if picked_edition in ("mokka", "dr460nized", "catppuccin") else "dr460nized",
        preset=preset,
        features=features,
        root=root_mount_point,
        hostname=hostname,
        username=username,
        state_version=nixosversion,
        flake_ref=os.environ.get("GNS_FLAKE_REF", gt.DEFAULT_FLAKE_REF),
        allow_unfree=bool(gs.value("nixos_allow_unfree")),
        bootloader=bootloader,
        grub_device=grub_device,
        kernel="cachyos",
        root_is_btrfs=root_is_btrfs,
        cryptodisk=cryptodisk,
        encrypted_swap=encrypted_swap,
        timezone=timezone,
        locale=locale,
        extra_locale=extra_locale,
        xkb_layout=xkb_layout,
        xkb_variant=xkb_variant,
        vconsole=vconsole,
        fullname=gs.value("fullname"),
        autologin=gs.value("autoLoginUser") is not None,
        partitions=partitions,
    )

    status = _("Generating NixOS configuration")
    libcalamares.job.setprogress(0.05)

    try:
        # Generate hardware.nix with mounted swap device
        subprocess.check_output(
            ["pkexec", "nixos-generate-config", "--root", root_mount_point],
            stderr=subprocess.STDOUT,
        )
    except subprocess.CalledProcessError as e:
        err = (e.output or b"").decode("utf8", "replace")
        libcalamares.utils.error(err)
        return (_("nixos-generate-config failed"), _(err))

    # Copy the flake template into the target, probe hardware with nixos-facter, and fill in
    # the placeholders and installer-picked sections.
    template_dir = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "..", "template"
    )
    gt.write_config(template_dir, nixos_dir, opts, hooks)
    gt.seed_persist(root_mount_point, nixos_dir,
                    log=libcalamares.utils.debug)

    status = _("Installing NixOS")
    libcalamares.job.setprogress(INSTALL_PROGRESS_START)

    try:
        subprocess.check_output(
            ["pkexec", "chmod", "755", root_mount_point],
            stderr=subprocess.STDOUT,
        )
    except subprocess.CalledProcessError as e:
        libcalamares.utils.warning(
            f"Failed to set permissions on {root_mount_point}: {e.output}"
        )

    # Build from the flake just written to the target, which already
    # contains the edition/features picked above
    nixosInstallCmd = ["pkexec"]
    nixosInstallCmd.extend(generateProxyStrings())
    nixosInstallCmd.extend(
        [
            "nixos-install",
            "--flake",
            os.path.join(root_mount_point, "etc/nixos") + "#" + hostname,
            "--no-root-passwd",
            "--root",
            root_mount_point,
            "--log-format",
            "internal-json",
            "--option",
            "build-dir",
            "/nix/var/nix/builds",
            "--option",
            "max-jobs",
            "2",
        ]
    )

    progress = NixProgress()

    try:
        output = ""
        proc = subprocess.Popen(
            nixosInstallCmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
        )
        assert proc.stdout is not None
        while True:
            line = proc.stdout.readline().decode("utf-8")
            if not line:
                break

            was_json = progress.handle(line)

            # Keep output for error reporting
            if not was_json:
                output += line
            for log_line in progress.log_messages:
                output += log_line + "\n"

            mapped = INSTALL_PROGRESS_START + progress.fraction * (
                INSTALL_PROGRESS_END - INSTALL_PROGRESS_START
            )
            libcalamares.job.setprogress(mapped)

            for log_line in progress.log_messages:
                libcalamares.utils.debug(f"nixos-install: {log_line}")
            progress.log_messages.clear()

            if not was_json:
                libcalamares.utils.debug(f"nixos-install: {line.strip()}")

        exit = proc.wait()
        if exit != 0:
            return (_("nixos-install failed"), _(output))
    except (OSError, subprocess.SubprocessError, UnicodeDecodeError):
        return (_("nixos-install failed"), _("Installation failed to complete"))

    libcalamares.job.setprogress(INSTALL_PROGRESS_END)
    return None
