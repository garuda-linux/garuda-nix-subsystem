#!/usr/bin/env python3
import os
import pwd
import sys
import unittest
from unittest import mock

sys.path.insert(0, os.path.normpath(os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "garuda-installer-lib")))

import gns_update as gu
import installer as inst


class TestApplyManaged(unittest.TestCase):
    def test_v1_migration_needs_host(self):
        with self.assertRaises(gu.UpdateError):
            gu.apply_managed({"version": 1, "v1": {}, "v2": {}},
                             None, "uuid", "none", 2)

    def test_v1_migration(self):
        out = gu.apply_managed({"version": 1, "v1": {"x": 1}, "v2": {}},
                               {}, "uuid", "kvm", 2)
        self.assertNotIn("v1", out)
        self.assertTrue(out["v2"]["subsystem"])
        self.assertEqual(out["v2"]["auto"],
                         {"uuid": "uuid", "hardware": {"virt": "kvm"}})

    def test_host_merge_replaces(self):
        config = {"version": 2, "hostname": "h",
                  "v2": {"subsystem": True,
                         "host": {"users": [{"name": "old"}]},
                         "auto": {"uuid": "x", "hardware": {"virt": "y"}}}}
        out = gu.apply_managed(config, {"users": [{"name": "new"}]},
                               "uuid", "none", 3)
        self.assertEqual(out["v2"]["host"], {"users": [{"name": "new"}]})
        self.assertEqual(out["version"], 3)

    def test_no_host_leaves_managed_untouched(self):
        config = {"version": 2, "hostname": "h",
                  "v2": {"subsystem": True,
                         "host": {"timezone": "Europe/Berlin"}}}
        out = gu.apply_managed(config, None, "uuid", "none", 2)
        self.assertEqual(out["v2"]["host"], {"timezone": "Europe/Berlin"})

    def test_empty_host_drops_stale_host(self):
        config = {"version": 2, "v2": {"host": {"users": []}}}
        out = gu.apply_managed(config, {}, "uuid", "none", 2)
        self.assertNotIn("host", out["v2"])


class TestCollectHost(unittest.TestCase):
    def test_users_carry_fullname_and_root_hash(self):
        entry = pwd.struct_passwd(
            ("nico", "x", 1000, 1000, "Nico Garuda,,,",
             "/home/nico", "/bin/bash"))
        hashes = {"nico": "$y$j9T$user", "root": "$y$j9T$root"}
        with mock.patch.object(gu.pwd, "getpwall", return_value=[entry]), \
             mock.patch.object(gu.grp, "getgrall", return_value=[]), \
             mock.patch.object(gu, "shadow_hash",
                               side_effect=lambda u: hashes.get(u, "")), \
             mock.patch.object(gu.subprocess, "check_output",
                               side_effect=OSError):
            host = gu.collect_host()
        self.assertEqual(host["users"][0]["fullname"], "Nico Garuda")
        self.assertEqual(host["hashed_root_password"], "$y$j9T$root")


class TestDefaultHostname(unittest.TestCase):
    def test_appends_nix_suffix(self):
        with mock.patch("builtins.open",
                        mock.mock_open(read_data="mokka\n")):
            self.assertEqual(inst.default_hostname(), "mokka-nix")

    def test_no_double_suffix(self):
        with mock.patch("builtins.open",
                        mock.mock_open(read_data="mokka-nix\n")):
            self.assertEqual(inst.default_hostname(), "mokka-nix")


class TestCmds(unittest.TestCase):
    def test_install_targets_host_flake(self):
        cmd = gu.build_install_cmd("/mnt", "host")
        self.assertIn("--log-format", cmd)
        self.assertIn("internal-json", cmd)
        self.assertIn("/mnt/etc/nixos#host", cmd)

    def test_rebuild_targets_host_flake(self):
        cmd = gu.build_rebuild_cmd("/mnt", "host")
        self.assertIn("--log-format", cmd)
        self.assertIn("internal-json", cmd)
        self.assertIn("host", cmd)
        self.assertIn("/mnt/etc/nixos", cmd)


if __name__ == "__main__":
    unittest.main()
