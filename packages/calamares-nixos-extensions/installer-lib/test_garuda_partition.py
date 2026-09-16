#!/usr/bin/env python3
"""Unit tests for garuda_partition pure functions."""
import unittest

import garuda_partition as gp


class TestPlanPartitions(unittest.TestCase):
    def test_efi_ext4(self):
        self.assertEqual(gp.plan_partitions("ext4", efi=True),
                         [("esp", "vfat", "/boot"), ("root", "ext4", "/")])

    def test_efi_btrfs(self):
        self.assertEqual(gp.plan_partitions("btrfs", efi=True),
                         [("esp", "vfat", "/boot"), ("root", "btrfs", "/")])

    def test_bios_gets_bios_boot(self):
        plan = gp.plan_partitions("btrfs", efi=False)
        self.assertEqual(plan[0][0], "bios-boot")
        self.assertEqual(plan[1], ("root", "btrfs", "/"))

    def test_luks_keeps_fs(self):
        self.assertEqual(gp.plan_partitions("luks-ext4")[1][1], "ext4")
        self.assertEqual(gp.plan_partitions("luks-btrfs")[1][1], "btrfs")

    def test_impermanence_is_btrfs(self):
        self.assertEqual(gp.plan_partitions("btrfs-impermanence")[1][1], "btrfs")
        self.assertEqual(gp.plan_partitions("luks-btrfs-impermanence")[1][1], "btrfs")

    def test_impermanence_mounts(self):
        self.assertEqual(gp.IMPERMANENCE_SUBVOLS, ("root", "home", "nix", "persist", "log"))
        rels = [rel for _, rel in gp.IMPERMANENCE_MOUNTS]
        self.assertEqual(rels, ["", "home", "nix", "persist", "var/log"])

    def test_tmpfs_root_schemas(self):
        self.assertTrue(gp.is_tmpfs_root("ext4-impermanence"))
        self.assertTrue(gp.is_tmpfs_root("luks-ext4-impermanence"))
        self.assertFalse(gp.is_tmpfs_root("ext4"))
        self.assertFalse(gp.is_tmpfs_root("btrfs-impermanence"))
        self.assertFalse(gp.is_tmpfs_root(None))

    def test_impermanence_plan_mounts_nix(self):
        self.assertEqual(gp.plan_partitions("ext4-impermanence")[1],
                         ("root", "ext4", "/nix"))
        self.assertEqual(gp.plan_partitions("btrfs-impermanence")[1],
                         ("root", "btrfs", "/nix"))
        self.assertEqual(gp.plan_partitions("btrfs")[1],
                         ("root", "btrfs", "/"))

    def test_unknown_schema(self):
        with self.assertRaises(gp.PartitionError):
            gp.plan_partitions("zfs")


class TestGarudaLayout(unittest.TestCase):
    def test_full_layout(self):
        self.assertEqual(
            [s for s, _ in gp.GARUDA_SUBVOLS],
            ["@", "@home", "@root", "@srv", "@nix", "@cache", "@log", "@tmp"])
        self.assertEqual(
            [r for _, r in gp.GARUDA_SUBVOLS],
            ["", "home", "root", "srv", "nix",
             "var/cache", "var/log", "var/tmp"])

    def test_matches_template_subvol_map(self):
        import garuda_template as gt
        hw = "\n".join(
            f'fileSystems."/{r}" = {{ options = [ "subvol=/{r or "/"}" ]; }};'
            if r else 'fileSystems."/" = { options = [ "subvol=/" ]; };'
            for _, r in gp.GARUDA_SUBVOLS)
        parts = [{"mountPoint": "/" if not r else f"/{r}", "fs": "btrfs"}
                 for _, r in gp.GARUDA_SUBVOLS]
        fixed = gt.fix_btrfs_subvolumes(hw, parts)
        for subvol, _ in gp.GARUDA_SUBVOLS:
            self.assertIn(f'"subvol={subvol}"', fixed)


class TestParseLsblk(unittest.TestCase):
    DATA = ('{"blockdevices": ['
            '{"name": "sda", "size": "100G", "model": "VMdisk", "type": "disk"},'
            '{"name": "sda1", "size": "100G", "model": null, "type": "part"},'
            '{"name": "sr0", "size": "1G", "model": "CDROM", "type": "rom"},'
            '{"name": "nvme0n1", "size": "500G", "model": null, "type": "disk"}'
            ']}')

    def test_lists_disks_only(self):
        self.assertEqual(
            gp._parse_lsblk(self.DATA),
            [("/dev/sda", "sda  100G  VMdisk"), ("/dev/nvme0n1", "nvme0n1  500G")])


class TestDiskPart(unittest.TestCase):
    def test_sata(self):
        self.assertEqual(gp._disk_part("/dev/sda", 1), "/dev/sda1")

    def test_nvme(self):
        self.assertEqual(gp._disk_part("/dev/nvme0n1", 2), "/dev/nvme0n1p2")

    def test_mmc(self):
        self.assertEqual(gp._disk_part("/dev/mmcblk0", 1), "/dev/mmcblk0p1")

    def test_parent_disk(self):
        self.assertEqual(gp.parent_disk("/dev/sda2"), "/dev/sda")
        self.assertEqual(gp.parent_disk("/dev/nvme0n1p2"), "/dev/nvme0n1")
        self.assertEqual(gp.parent_disk("/dev/mmcblk0p1"), "/dev/mmcblk0")

    def test_mounted_layout(self):
        self.assertEqual(gp.mounted_layout("ext4"), [("/", "ext4")])
        layout = gp.mounted_layout("btrfs")
        self.assertEqual(layout[0], ("/", "btrfs"))
        self.assertIn(("/home", "btrfs"), layout)
        self.assertEqual(len(layout), len(gp.GARUDA_SUBVOLS))
        self.assertEqual(gp.mounted_layout("ext4-impermanence"),
                         [("/nix", "ext4")])
        layout = gp.mounted_layout("btrfs-impermanence")
        self.assertEqual(layout[0], ("/", "btrfs"))
        self.assertIn(("/persist", "btrfs"), layout)

    def test_cmd_prefix_empty_by_default(self):
        self.assertEqual(gp.CMD_PREFIX, [])


if __name__ == "__main__":
    unittest.main()
