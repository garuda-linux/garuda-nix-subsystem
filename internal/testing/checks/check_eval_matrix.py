#!/usr/bin/env python3
"""Render every offered edition feature-set and nix-eval the result.

Catches template typos that still parse but fail evaluation.

Usage:
  python3 /tmp/check_eval_matrix.py /tmp/tmpl /tmp/repo
"""
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import garuda_template as gt

TEMPLATE_DIR = sys.argv[1] if len(sys.argv) > 1 else "/tmp/tmpl"
REPO_DIR = sys.argv[2] if len(sys.argv) > 2 else "/tmp/repo"

# One entry per thing the installer lets the user pick.
COMBOS = [
    ("mokka", ["gaming"]),
    ("mokka", []),
    ("dr460nized", ["performance", "printing"]),
    ("catppuccin", ["powersave", "samba"]),
]


class SkipFacterScan(gt.Hooks):
    """No hardware prober in this VM: pretend the facter scan failed."""

    def run(self, cmd):
        raise OSError("skip facter scan")


def main():
    Path("/tmp/fake-hw.nix").write_text(
        '{ fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; }; }')
    for edition, features in COMBOS:
        out_dir = Path(f"/tmp/out-{edition}-{len(features)}")
        shutil.rmtree(out_dir, ignore_errors=True)
        out_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy("/tmp/fake-hw.nix", out_dir / "hardware-configuration.nix")

        opts = gt.InstallOpts(edition=edition, features=features,
                              flake_ref=f"path:{REPO_DIR}")
        gt.write_config(TEMPLATE_DIR, str(out_dir), opts, SkipFacterScan())

        r = subprocess.run(
            ["nix", "--extra-experimental-features", "nix-command flakes",
             "eval", "--impure", "--accept-flake-config",
             f"{out_dir}#nixosConfigurations.garuda-nix.config.system.build.toplevel.outPath",
             "--show-trace"],
            capture_output=True, text=True, check=False)
        print(("PASS " if r.returncode == 0 else "FAIL ") + f"{edition}/{features}")
        assert r.returncode == 0, r.stderr[-2000:]
    print("eval-matrix OK")


if __name__ == "__main__":
    main()
