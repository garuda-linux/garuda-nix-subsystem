#!/usr/bin/env python3
"""Render every installer edition bootloader combo and sanity-check output.

1. Renders the template for each (edition, features, bootloader) combo.
2. Asserts no @@MARKERS@@ survived and the edition line is present.
3. Asserts both generated files still parse as Nix.
4. Checks the nixos-facter helper emits the NVIDIA section.

Usage:
  python3 /tmp/check_installer_template.py /tmp/tmpl
"""
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import garuda_template as gt

TEMPLATE_DIR = sys.argv[1] if len(sys.argv) > 1 else "/tmp/tmpl"

# One entry per thing the installer UI lets the user pick.
COMBOS = [
    ("mokka", ["gaming"], "systemd-boot"),
    ("dr460nized", ["performance", "printing", "scanning"], "grub"),
    ("catppuccin", ["powersave", "samba", "btrfs-maintenance"], "none"),
    ("mokka", [], "systemd-boot"),
]


class SkipFacterScan(gt.Hooks):
    """No hardware prober in this VM: pretend the facter scan failed."""

    def run(self, cmd):
        raise OSError("skip facter scan")


def main():
    failures = []

    def check(name, cond, detail=""):
        print(("PASS " if cond else "FAIL ") + name)
        if not cond:
            failures.append(name + " :: " + detail[-500:])

    for edition, features, bootloader in COMBOS:
        out_dir = Path(f"/tmp/out-{edition}-{bootloader}")
        shutil.rmtree(out_dir, ignore_errors=True)
        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / "hardware-configuration.nix").write_text("{ }")

        opts = gt.InstallOpts(edition=edition, features=features, bootloader=bootloader)
        gt.write_config(TEMPLATE_DIR, str(out_dir), opts, SkipFacterScan())

        text = (out_dir / "nixos/configuration.nix").read_text()
        flake = (out_dir / "flake.nix").read_text()
        label = f"{edition}/{bootloader}"

        check(label + " no-markers",
              all(m not in text and m not in flake for m in gt.MARKERS), text[-800:])

        check(label + " edition",
              f"garuda.{edition}.enable = true" in text, text[-800:])
              
        for fname in ("nixos/configuration.nix", "flake.nix"):
            r = subprocess.run(["nix-instantiate", "--parse", str(out_dir / fname)],
                               capture_output=True, text=True, check=False)
            check(label + f" {fname} parses", r.returncode == 0, r.stderr)
    assert not failures, "\n".join(failures)
    print("all-combos OK")

    report = {"hardware": {"graphics_card": [
        {"vendor": {"hex": "10de"}, "sysfs_bus_id": "0000:01:00.0"}]}}
    lines = "\n".join(gt.build_facter_section(report))
    assert "garuda.hardware.autoDriver.reportPath" in lines, lines
    assert "garuda.hardware.nvidia.enable = true" in lines, lines
    print("facter-section OK")


if __name__ == "__main__":
    main()
