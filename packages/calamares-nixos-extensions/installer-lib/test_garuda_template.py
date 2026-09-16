#!/usr/bin/env python3
"""Unit tests for garuda_template pure functions (no I/O, no nix store)."""
import unittest

import garuda_template as gt

NVIDIA = {"vendor": {"hex": "10de"}, "sysfs_bus_id": "0000:01:00.0"}


def nvidia_card(**overrides):
    return {"vendor": {"hex": "10de"}, "sysfs_bus_id": "0000:01:00.0"} | overrides


class TestNixEscape(unittest.TestCase):
    def test_cases(self):
        for raw, want in [("eth0", "eth0"), ('say "hi"', 'say \\"hi\\"'), (42, "42")]:
            with self.subTest(raw=raw):
                self.assertEqual(gt.nix_escape(raw), want)


class TestFacterPciId(unittest.TestCase):
    def test_cases(self):
        cases = [
            ({"sysfs_bus_id": "0000:01:00.0"}, "PCI:1:0:0"),
            ({"sysfs_bus_id": "0000:0a:1b.1"}, "PCI:10:27:1"),
            ({}, None),
            ({"sysfs_bus_id": "garbage"}, None),
        ]
        for card, want in cases:
            with self.subTest(card=card):
                self.assertEqual(gt.facter_pci_id(card), want)


class TestDetectGpus(unittest.TestCase):
    def test_cases(self):
        nvidia = nvidia_card()
        amd = {"vendor": {"hex": "1002"}, "sysfs_bus_id": "0000:03:00.0"}
        drv = nvidia_card(vendor={"hex": "0000"}, driver="nvidia",
                          sysfs_bus_id="0000:02:00.0")
        cases = [
            ({"hardware": {"graphics_card": [nvidia]}}, (True, "PCI:1:0:0", None)),
            ({"hardware": {"graphics_card": [drv]}}, (True, "PCI:2:0:0", None)),
            ({"hardware": {"graphics_card": [amd]}}, (False, None, "PCI:3:0:0")),
            ({}, (False, None, None)),
        ]
        for report, want in cases:
            with self.subTest(report=report):
                self.assertEqual(gt.detect_gpus(report), want)


class TestFixBtrfsSubvolumes(unittest.TestCase):
    def test_cases(self):
        bogus = 'fileSystems."/" = { device = "/dev/sda1"; fsType = "btrfs"; options = [ "subvol=/" ]; };'
        ext4 = 'fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };'
        home = 'fileSystems."/home" = { options = [ "subvol=@home" ]; };'
        cases = [
            # (hw, parts, check): check is a substring to find, or full text to equal
            (bogus, [{"mountPoint": "/", "fs": "btrfs"}], ("in", "subvol=@")),
            (ext4, [{"mountPoint": "/", "fs": "ext4"}], ("eq", ext4)),
            (home, [{"mountPoint": "/", "fs": "btrfs"}], ("eq", home)),
        ]
        for hw, parts, (mode, want) in cases:
            with self.subTest(hw=hw):
                fixed = gt.fix_btrfs_subvolumes(hw, parts)
                if mode == "in":
                    self.assertIn(want, fixed)
                else:
                    self.assertEqual(fixed, want)


def section_lines(func, *args):
    return "\n".join(func(*args))


class TestBuildGarudaSection(unittest.TestCase):
    def test_mokka_gaming(self):
        lines = section_lines(gt.build_garuda_section,
                              gt.InstallOpts(flavor="mokka", features=["gaming"]))
        self.assertIn("garuda.mokka.enable = true", lines)
        self.assertIn("garuda.gaming.enable = true", lines)

    def test_performance_wins_over_powersave(self):
        warned = []
        opts = gt.InstallOpts(flavor="dr460nized", features=["performance", "powersave"])
        lines = section_lines(gt.build_garuda_section, opts, warned.append)
        self.assertIn("garuda.performance-tweaks.enable = true", lines)
        self.assertNotIn("powersave", lines)
        self.assertTrue(warned)

    def test_unknown_flavor_and_features(self):
        lines = section_lines(gt.build_garuda_section,
                              gt.InstallOpts(flavor="nope", features=["bogus"]))
        self.assertIn("garuda.dr460nized.enable = true", lines)
        self.assertNotIn("bogus", lines)


class TestBuildBootloaderSection(unittest.TestCase):
    def test_cases(self):
        cases = [
            (gt.InstallOpts(bootloader="systemd-boot"),
             "boot.loader.systemd-boot.enable = true"),
            (gt.InstallOpts(bootloader="grub"), "boot.loader.grub.enable = false"),
            (gt.InstallOpts(bootloader="grub", grub_device="/dev/sda"),
             'boot.loader.grub.device = "/dev/sda"'),
            (gt.InstallOpts(bootloader="none"), "boot.loader.grub.enable = false"),
        ]
        for opts, want in cases:
            with self.subTest(opts=opts):
                self.assertIn(want, section_lines(gt.build_bootloader_section, opts))


class TestBuildFacterSection(unittest.TestCase):
    def test_nvidia_report(self):
        report = {"hardware": {"graphics_card": [dict(NVIDIA)]}}
        lines = section_lines(gt.build_facter_section, report)
        self.assertIn("garuda.hardware.autoDriver.reportPath", lines)
        self.assertIn("garuda.hardware.nvidia.enable = true", lines)
        self.assertIn('garuda.hardware.nvidia.nvidiaBusId = "PCI:1:0:0"', lines)

    def test_no_gpu(self):
        lines = section_lines(gt.build_facter_section, {})
        self.assertIn("garuda.hardware.autoDriver.reportPath", lines)
        self.assertNotIn("nvidia.enable", lines)


class TestInstallOpts(unittest.TestCase):
    def test_defaults(self):
        opts = gt.InstallOpts()
        self.assertEqual((opts.flavor, opts.hostname, opts.username, opts.allow_unfree),
                         ("mokka", "garuda-nix", "garuda", True))


if __name__ == "__main__":
    unittest.main()
