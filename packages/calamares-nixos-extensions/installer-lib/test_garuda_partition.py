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

    def test_unknown_schema(self):
        with self.assertRaises(gp.PartitionError):
            gp.plan_partitions("zfs")


class TestDiskPart(unittest.TestCase):
    def test_sata(self):
        self.assertEqual(gp._disk_part("/dev/sda", 1), "/dev/sda1")

    def test_nvme(self):
        self.assertEqual(gp._disk_part("/dev/nvme0n1", 2), "/dev/nvme0n1p2")

    def test_mmc(self):
        self.assertEqual(gp._disk_part("/dev/mmcblk0", 1), "/dev/mmcblk0p1")


if __name__ == "__main__":
    unittest.main()
