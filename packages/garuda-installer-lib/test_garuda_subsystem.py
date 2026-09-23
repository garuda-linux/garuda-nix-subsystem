#!/usr/bin/env python3
"""Unit tests for garuda_subsystem git helpers."""

import io
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

import garuda_subsystem as gs

GIT = shutil.which("git")


@unittest.skipUnless(GIT, "git not installed")
class TestGitCommit(unittest.TestCase):
    def test_init_and_commit(self):
        d = tempfile.mkdtemp()
        try:
            with open(os.path.join(d, "flake.nix"), "w") as f:
                f.write('{}\n')

            gs.git_commit(d, "initial")
            log = subprocess.check_output(
                ["git", "-C", d, "log", "--format=%s"], text=True)
            self.assertEqual(log.strip(), "initial")
        finally:
            shutil.rmtree(d, ignore_errors=True)

    def test_noop_when_clean(self):
        d = tempfile.mkdtemp()
        try:
            with open(os.path.join(d, "flake.nix"), "w") as f:
                f.write('{}\n')

            gs.git_commit(d, "initial")
            gs.git_commit(d, "second")
            log = subprocess.check_output(
                ["git", "-C", d, "log", "--format=%s"], text=True)
            self.assertEqual(log.strip().splitlines(), ["initial"])
        finally:
            shutil.rmtree(d, ignore_errors=True)


class TestStep(unittest.TestCase):
    def test_plain_on_non_tty(self):
        err = io.StringIO()
        err.isatty = lambda: False
        with mock.patch.object(sys, "stderr", err):
            gs.step("Mounting 🍵")
        self.assertEqual(err.getvalue(), "» Mounting 🍵\n")

    def test_green_marker_on_tty(self):
        err = io.StringIO()
        err.isatty = lambda: True
        with mock.patch.object(sys, "stderr", err):
            gs.step("Mounting 🍵")
        out = err.getvalue()
        self.assertIn("\033[1;32m»\033[0m Mounting 🍵", out)


if __name__ == "__main__":
    unittest.main()
