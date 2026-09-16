#!/usr/bin/env python3
"""Shared template-filling core for the Garuda NixOS installer.

Used by both frontends:
- the Calamares nixos module (modules/nixos/main.py)
- the install-garuda-nix CLI (packages/install-garuda-nix)
"""

import json
import os
import re
import shutil
import subprocess
from dataclasses import dataclass, field

# Garuda Nix options selectable in the installer.
# The Calamares edition picker writes "mokka"/"dr460nized", the features
# picker appends garuda-feature-* marker names; the CLI takes --edition
# and repeatable --feature flags using the keys below.
GARUDA_FEATURES = {
    "gaming": "garuda.gaming",
    "performance": "garuda.performance-tweaks",
    "powersave": "garuda.powersave-tweaks",
    "printing": "garuda.printing",
    "scanning": "garuda.scanning",
    "samba": "garuda.samba",
    "btrfs-maintenance": "garuda.btrfs-maintenance",
    "impermanence": "garuda.impermanence",
}

GARUDA_PRESETS = ("desktop", "laptop", "server", "handheld")

PRESET_EXCLUDES = {"desktop": "powersave", "handheld": "powersave",
                   "laptop": "performance"}


def check_preset_features(preset, features):
    """Raise ValueError when a feature clashes with the preset."""
    if (preset in PRESET_EXCLUDES
            and PRESET_EXCLUDES[preset] in (features or [])):
        raise ValueError(
            f"preset {preset!r} conflicts with the "
            f"{PRESET_EXCLUDES[preset]} feature"
        )

DEFAULT_FLAKE_REF = "gitlab:garuda-linux/garuda-nix-subsystem/stable"

MARKERS = ("@@GARUDA@@", "@@FACTER@@", "@@BOOTLOADER@@", "@@SYSTEM@@", "@@USER@@")

TEMPLATE_FILES = ("flake.nix", "nixos/configuration.nix", "home-manager/home.nix")


@dataclass
class InstallOpts:
    """Everything needed to fill the template. Frontends translate
    their own inputs (Calamares GlobalStorage, CLI flags) into this."""

    # Garuda edition, preset and features
    edition: str = "mokka"
    preset: str | None = None
    features: list = field(default_factory=list)

    # Target
    root: str = "/mnt"

    # Placeholders
    hostname: str = "garuda-nix"
    username: str = "garuda"
    state_version: str = "26.11"
    flake_ref: str = DEFAULT_FLAKE_REF
    allow_unfree: bool = True

    # Bootloader: "systemd-boot", "grub" or "none"
    bootloader: str = "systemd-boot"
    grub_device: str | None = None

    # cachyos (default, from chaotic-nyx) or lts (nixpkgs default)
    kernel: str = "cachyos"
    root_is_btrfs: bool = False
    tmpfs_root: bool = False
    cryptodisk: bool = False
    encrypted_swap: list = field(default_factory=list)

    # System section
    timezone: str | None = None
    locale: str | None = None
    extra_locale: dict = field(default_factory=dict)
    xkb_layout: str | None = None
    xkb_variant: str | None = None
    vconsole: str | None = None

    # User section
    fullname: str | None = None
    autologin: bool = True

    # Calamares partition list for the btrfs subvol fix, None to skip
    partitions: list | None = None

    def __post_init__(self):
        self.features = list(self.features or [])
        self.encrypted_swap = list(self.encrypted_swap or [])
        if self.preset not in GARUDA_PRESETS:
            self.preset = None        
        self.extra_locale = dict(self.extra_locale or {})
        self.hostname = self.hostname or "garuda-nix"
        self.username = self.username or "garuda"
        self.state_version = self.state_version or "26.11"
        self.flake_ref = self.flake_ref or DEFAULT_FLAKE_REF

        check_preset_features(self.preset, self.features)


class Hooks:
    """Frontend side effects. Defaults fit a CLI running as root."""

    def run(self, cmd):
        """Run cmd, return stdout bytes. Raises on failure."""
        return subprocess.check_output(cmd, stderr=subprocess.STDOUT)

    def warn(self, msg):
        print(f"warning: {msg}")

    def write_file(self, path, text):
        with open(path, "w") as f:
            f.write(text)


def nix_escape(s):
    return json.dumps(str(s))[1:-1]


def facter_pci_id(card):
    """NixOS PRIME bus ID ("PCI:bus:device:function", decimal) from a
    nixos-facter graphics_card entry's sysfs_bus_id ("DDDD:BB:DD.F")."""
    m = re.match(
        r"^[0-9a-fA-F]{4}:([0-9a-fA-F]{2}):([0-9a-fA-F]{2})\.(\d)$",
        card.get("sysfs_bus_id") or "",
    )
    if not m:
        return None

    bus, device, function = m.groups()
    return f"PCI:{int(bus, 16)}:{int(device, 16)}:{function}"


def detect_gpus(report):
    """(has_nvidia, nvidia_id, amd_id) from a nixos-facter report.
    Bus IDs are NixOS PRIME IDs, None where they cannot be derived.
    Matches on PCI vendor id with the loaded kernel driver as fallback."""
    has_nvidia = False
    nvidia_id = amd_id = None

    for card in (report.get("hardware") or {}).get("graphics_card") or []:
        vendor = ((card.get("vendor") or {}).get("hex") or "").lower()
        drivers = " ".join(
            str(d).lower()
            for d in (
                [card.get("driver"), card.get("driver_module")]
                + list(card.get("driver_modules") or [])
            )
            if d
        )
        is_nvidia = vendor == "10de" or "nvidia" in drivers or "nouveau" in drivers
        is_amd = vendor == "1002" or "amdgpu" in drivers or "radeon" in drivers
        if is_nvidia:
            has_nvidia = True
            if nvidia_id is None:
                nvidia_id = facter_pci_id(card)
        elif is_amd and amd_id is None:
            amd_id = facter_pci_id(card)
    return has_nvidia, nvidia_id, amd_id


def fix_btrfs_subvolumes(hardware_config, partitions, log=None):
    """Rewrite bogus subvol=<mountpoint> values to @-style names."""
    subvol_map = {
        "/": "@",
        "/home": "@home",
        "/root": "@root",
        "/srv": "@srv",
        "/nix": "@nix",
        "/var/cache": "@cache",
        "/var/log": "@log",
        "/var/tmp": "@tmp",
    }

    root_is_btrfs = any(
        part.get("mountPoint") == "/" and part.get("fs") == "btrfs"
        for part in partitions or []
    )
    if not root_is_btrfs:
        return hardware_config

    if log is not None:
        log("Fixing btrfs subvolume configuration")

    # Rewrite only bogus values, leave correct ones untouched.
    for mount_point, correct_subvol in subvol_map.items():
        wrong = "|".join(
            sorted(
                re.escape(v) for v in {mount_point, "/"} if v != correct_subvol
            )
        )
        pattern = rf'(fileSystems\."{re.escape(mount_point)}"[^\n]*?"subvol=)(?:{wrong})"'
        replacement = rf'\g<1>{correct_subvol}"'
        hardware_config = re.sub(pattern, replacement, hardware_config)

    return hardware_config


def build_garuda_section(opts, warn=None):
    lines = []
    if opts.edition == "mokka":
        lines.append("  garuda.mokka.enable = true;")
    elif opts.edition == "catppuccin":
        lines.append("  garuda.catppuccin.enable = true;")
    else:
        lines.append("  garuda.dr460nized.enable = true;")

    if opts.preset is not None:
        lines.append(f'  garuda.preset = "{opts.preset}";')

    selected = [f for f in opts.features if f in GARUDA_FEATURES]
    if "performance" in selected and "powersave" in selected:
        # The modules are mutually exclusive; prefer performance.
        if warn is not None:
            warn("Both performance and powersave tweaks selected, keeping performance.")
        selected.remove("powersave")

    for item in selected:
        lines.append(f"  {GARUDA_FEATURES[item]}.enable = true;")

    if "impermanence" in selected:
        lines.append(
            f'  garuda.impermanence.persistentUsers = [ "{nix_escape(opts.username)}" ];'
        )

    if "impermanence" in selected and opts.tmpfs_root:
        lines.append("  garuda.impermanence.tmpfsRoot = true;")
    lines.append("")
    return lines


def build_bootloader_section(opts):
    lines = []
    if opts.bootloader == "systemd-boot":
        lines.append("  boot.loader.systemd-boot.enable = true;")
        lines.append("  boot.loader.efi.canTouchEfiVariables = true;")
    elif opts.bootloader == "grub":
        if not opts.grub_device:
            lines.append("  boot.loader.grub.enable = false;")
        else:
            lines.append("  boot.loader.grub.enable = true;")
            lines.append(f'  boot.loader.grub.device = "{nix_escape(opts.grub_device)}";')
            lines.append("  boot.loader.grub.useOSProber = true;")
            if opts.root_is_btrfs:
                lines.append('  boot.loader.grub.fsIdentifier = "provided";')
    else:
        lines.append("  boot.loader.grub.enable = false;")
    lines.append("")

    if opts.kernel == "cachyos":
        lines.append("  # Use the CachyOS kernel (via chaotic-nyx).")
        lines.append("  boot.kernelPackages = pkgs.linuxPackages_cachyos;")
        lines.append("")

    for swap in opts.encrypted_swap:
        lines.append(
            f'  boot.initrd.luks.devices."{swap["mapper"]}".device = "/dev/disk/by-uuid/{swap["uuid"]}";'
        )
    if opts.encrypted_swap:
        lines.append("")

    if opts.cryptodisk and opts.bootloader == "grub" and opts.grub_device:
        lines.append("  # Setup keyfile")
        lines.append("  boot.initrd.secrets = {")
        lines.append('    "/boot/crypto_keyfile.bin" = null;')
        lines.append("  };")
        lines.append("")
        lines.append("  boot.loader.grub.enableCryptodisk = true;")
        lines.append("")
    return lines


def build_system_section(opts):
    lines = []
    lines.append(f'  networking.hostName = "{nix_escape(opts.hostname)}";')
    lines.append("")
    if opts.timezone:
        lines.append("  # Set your time zone.")
        lines.append(f'  time.timeZone = "{nix_escape(opts.timezone)}";')
        lines.append("")
    if opts.locale:
        lines.append("  # Select internationalisation properties.")
        lines.append(f'  i18n.defaultLocale = "{nix_escape(opts.locale)}";')
        lines.append("")
        if set(opts.extra_locale.values()) != {opts.locale}:
            lines.append("  i18n.extraLocaleSettings = {")
            for key in (
                "LC_ADDRESS",
                "LC_IDENTIFICATION",
                "LC_MEASUREMENT",
                "LC_MONETARY",
                "LC_NAME",
                "LC_NUMERIC",
                "LC_PAPER",
                "LC_TELEPHONE",
                "LC_TIME",
            ):
                if key in opts.extra_locale:
                    lines.append(f'    {key} = "{nix_escape(opts.extra_locale[key])}";')
            lines.append("  };")
            lines.append("")
    if opts.xkb_layout:
        lines.append("  # Configure keymap in X11")
        lines.append("  services.xserver.xkb = {")
        lines.append(f'    layout = "{nix_escape(opts.xkb_layout)}";')
        lines.append(f'    variant = "{nix_escape(opts.xkb_variant or "")}";')
        lines.append("  };")
        lines.append("")
    if opts.vconsole:
        lines.append("  # Configure console keymap")
        lines.append(f'  console.keyMap = "{nix_escape(opts.vconsole)}";')
        lines.append("")
    return lines


def build_user_section(opts):
    lines = []
    lines.append(
        "  # Define a user account. Don't forget to set a password with ‘passwd’."
    )
    lines.append(f'  users.users."{nix_escape(opts.username)}" = {{')
    lines.append("    isNormalUser = true;")

    if opts.fullname:
        lines.append(f'    description = "{nix_escape(opts.fullname)}";')
    lines.append('    extraGroups = [ "networkmanager" "wheel" ];')
    lines.append("  };")
    lines.append("")
    
    if opts.autologin:
        lines.append("  # Enable automatic login for the user.")
        lines.append("  services.displayManager.autoLogin.enable = true;")
        lines.append(f'  services.displayManager.autoLogin.user = "{nix_escape(opts.username)}";')
        lines.append("")
    lines.append(f'  home-manager.users."{nix_escape(opts.username)}" = import ../home-manager/home.nix;')
    lines.append("")
    return lines


def build_facter_section(report):
    lines = [
        "  # Hardware probed during installation, see ./facter.json.",
        "  garuda.hardware.autoDriver.reportPath = ./facter.json;",
    ]
    nvidia, nvidia_id, amd_id = detect_gpus(report)
    if nvidia:
        lines.append("  # Auto-detected NVIDIA GPU, enable the proprietary driver.")
        lines.append("  garuda.hardware.nvidia.enable = true;")
        if nvidia_id is not None:
            lines.append(f'  garuda.hardware.nvidia.nvidiaBusId = "{nvidia_id}";')
        if amd_id is not None:
            lines.append(f'  garuda.hardware.nvidia.amdgpuBusId = "{amd_id}";')
    lines.append("")
    return lines


def run_facter_scan(facter_path, hooks):
    """Probe the host hardware. Returns the parsed report, or None on failure."""
    try:
        hooks.run(["nixos-facter", "-o", facter_path])
        with open(facter_path, "r") as f:
            return json.load(f)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError) as e:
        hooks.warn(f"nixos-facter scan failed: {e}")
        return None


def fix_tmpfs_root(hardware_config):
    tmpfs = (
        '  fileSystems."/" =\n'
        '    { device = "none";\n'
        '      fsType = "tmpfs";\n'
        '      options = [ "defaults" "size=25%" "mode=755" ];\n'
        '    };\n'
    )
    replaced, count = re.subn(
        r'  fileSystems\."/"\s*=\s*\{[^}]*\};\n', tmpfs, hardware_config
    )
    if count:
        return replaced
    return hardware_config.rstrip()[: -1].rstrip() + "\n\n" + tmpfs + "}\n"


def fix_impermanence_needed_for_boot(hardware_config):
    return re.sub(
        r'(  fileSystems\."[^"]+"\s*=\s*\n\s*\{)',
        r"\1      neededForBoot = true;\n",
        hardware_config,
    )


def fix_hardware_config(hw_config, opts, hooks):
    """Apply the btrfs subvol fix and strip unfree kernel modules unless allowed."""
    with open(hw_config, "r") as f:
        htxt = f.read()

    modified = False
    if opts.tmpfs_root:
        htxt = fix_tmpfs_root(htxt)
        modified = True
    if "impermanence" in opts.features:
        htxt = fix_impermanence_needed_for_boot(htxt)
        modified = True
    fixed = fix_btrfs_subvolumes(htxt, opts.partitions)
    if fixed != htxt:
        htxt = fixed
        modified = True

    search = re.search(r"boot\.extraModulePackages = \[ (.*) \];", htxt)
    if search is not None and not opts.allow_unfree:
        kept = []
        for pkg in search.group(1).split(" "):
            p = ".".join(pkg.split(".")[3:])
            isunfree = hooks.run(
                [
                    "nix-instantiate",
                    "--eval",
                    "--strict",
                    "-E",
                    f"with import <nixpkgs> {{}}; pkgs.linuxKernel.packageAliases.linux_default.{p}.meta.unfree",
                    "--json",
                ]
            )
            if isunfree.strip() == b"true":
                hooks.warn(
                    f"{p} is marked as unfree, removing from hardware-configuration.nix"
                )
            else:
                kept.append(pkg)
        joined = "".join(pkg + " " for pkg in kept)
        htxt = re.sub(
            r"boot\.extraModulePackages = \[ (.*) \];",
            f"boot.extraModulePackages = [ {joined}];",
            htxt,
        )
        modified = True

    if modified:
        hooks.write_file(hw_config, htxt)


def write_config(template_dir, nixos_dir, opts, hooks=None):
    """Copy the template into the target and fill placeholders/sections.

    Expects nixos-generate-config --root <root> to have run already, so
    <root>/etc/nixos/hardware-configuration.nix exists and is moved next
    to the template's nixos/configuration.nix.
    """
    hooks = hooks or Hooks()
    hw_config = os.path.join(nixos_dir, "nixos/hardware-configuration.nix")
    shutil.copytree(template_dir, nixos_dir, dirs_exist_ok=True)
    os.rename(
        os.path.join(nixos_dir, "hardware-configuration.nix"),
        hw_config,
    )
    # nixos-generate-config also drops a default configuration.nix next to
    # it; the template replaces it, so remove the stale file.
    stale = os.path.join(nixos_dir, "configuration.nix")
    if os.path.exists(stale):
        os.remove(stale)

    # Probe the host hardware. The report drives the facter module
    # and auto-enables the NVIDIA driver.
    report = run_facter_scan(os.path.join(nixos_dir, "nixos", "facter.json"), hooks)
    if report is not None:
        facter_lines = build_facter_section(report)
    else:
        facter_lines = [
            "  # nixos-facter scan failed, hardware auto-detection skipped.",
            "",
        ]

    sections = {
        "@@GARUDA@@": build_garuda_section(opts, hooks.warn),
        "@@FACTER@@": facter_lines,
        "@@BOOTLOADER@@": build_bootloader_section(opts),
        "@@SYSTEM@@": build_system_section(opts),
        "@@USER@@": build_user_section(opts),
    }

    fix_hardware_config(hw_config, opts, hooks)

    placeholders = {
        "@HOSTNAME@": opts.hostname,
        "@USERNAME@": opts.username,
        "@STATEVERSION@": opts.state_version,
        "@GARUDAREF@": opts.flake_ref,
    }
    for name in TEMPLATE_FILES:
        path = os.path.join(nixos_dir, name)
        with open(path, "r") as f:
            text = f.read()
        for token, value in placeholders.items():
            text = text.replace(token, value)
        for marker, section in sections.items():
            text = text.replace("  # " + marker, "\n".join(section).rstrip())
        if not opts.allow_unfree:
            text = text.replace("allowUnfree = true", "allowUnfree = false")
        hooks.write_file(path, text)

    return os.path.join(nixos_dir, "flake.nix")
