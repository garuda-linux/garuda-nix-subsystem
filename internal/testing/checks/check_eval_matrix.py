#!/usr/bin/env python3
"""Render every offered edition feature-set and nix-eval the result.

Catches template typos that still parse but fail evaluation.

Usage:
  python3 /tmp/check_eval_matrix.py /tmp/tmpl /tmp/repo
"""
import json
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import garuda_template as gt

TEMPLATE_DIR = sys.argv[1] if len(sys.argv) > 1 else "/tmp/tmpl"
REPO_DIR = sys.argv[2] if len(sys.argv) > 2 else "/tmp/repo"

NVIDIA_DGPU = {"hardware": {"graphics_card": [
    {"vendor": {"hex": "10de"}, "driver": "nvidia",
     "sysfs_bus_id": "0000:01:00.0"},
]}}
PRIME_AMD_NVIDIA = {"hardware": {"graphics_card": [
    {"vendor": {"hex": "1002"}, "driver": "amdgpu",
     "sysfs_bus_id": "0000:05:00.0"},
    {"vendor": {"hex": "10de"}, "driver": "nvidia",
     "sysfs_bus_id": "0000:01:00.0"},
]}}

COMBOS = [
    ("mokka", ["gaming"], None),
    ("mokka", [], None),
    ("dr460nized", ["performance", "printing"], None),
    ("catppuccin", ["powersave", "samba"], None),
    ("mokka", ["gaming"], NVIDIA_DGPU),
    ("dr460nized", ["performance", "printing"], PRIME_AMD_NVIDIA),
]


class SkipFacterScan(gt.Hooks):
    """Serve a canned facter report (or pretend the scan failed)."""

    def __init__(self, report=None):
        self.report = report

    def run(self, cmd):
        if "facter" in cmd[0]:
            if self.report is None:
                raise OSError("skip facter scan")
            Path(cmd[cmd.index("-o") + 1]).write_text(json.dumps(self.report))
            return b""
        return super().run(cmd)


def main():
    Path("/tmp/fake-hw.nix").write_text(
        '{ fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; }; }')
    for i, (edition, features, report) in enumerate(COMBOS):
        out_dir = Path(f"/tmp/out-{i}-{edition}")
        shutil.rmtree(out_dir, ignore_errors=True)
        out_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy("/tmp/fake-hw.nix", out_dir / "hardware-configuration.nix")

        opts = gt.InstallOpts(edition=edition, features=features,
                              flake_ref=f"path:{REPO_DIR}")
        gt.write_config(TEMPLATE_DIR, str(out_dir), opts,
                        SkipFacterScan(report))

        r = subprocess.run(
            ["nix", "--extra-experimental-features", "nix-command flakes",
             "eval", "--impure", "--accept-flake-config",
             f"{out_dir}#nixosConfigurations.garuda-nix.config.system.build.toplevel.outPath",
             "--show-trace"],
            capture_output=True, text=True, check=False)
        tag = f"{edition}/{features}" + ("+gpu" if report else "")
        print(("PASS " if r.returncode == 0 else "FAIL ") + tag)
        assert r.returncode == 0, r.stderr[-2000:]
    print("eval-matrix OK")


if __name__ == "__main__":
    main()
