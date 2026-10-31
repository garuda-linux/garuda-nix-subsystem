#!/usr/bin/env python3
import os
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import fixes
import nixedit
import runner

try:
    nixedit.parse(b"{ }")
    HAVE_TS = True
except nixedit.Unavailable:
    HAVE_TS = False

FLAKE = b"""{
  description = "gitlab:garuda-linux/garuda-nix/stable";
  inputs = {
    # keep me
    garuda.url = "gitlab:garuda-linux/garuda-nix/stable";
    other = { url = "gitlab:someone/else/main"; };
  };
  inputs.old.url = "gitlab:garuda-linux/garuda-nix-subsystem";
  outputs = { garuda, ... }: { thing.url = "gitlab:not/an-input"; };
}
"""


@unittest.skipUnless(HAVE_TS, "tree-sitter-nix is not installed")
class TestNixEdit(unittest.TestCase):
    def test_bindings_follow_nested_sets(self):
        paths = [p for p, _ in nixedit.bindings(nixedit.parse(FLAKE))]
        self.assertIn(("inputs", "garuda", "url"), paths)
        self.assertIn(("inputs", "other", "url"), paths)
        self.assertIn(("inputs", "old", "url"), paths)

    def test_bindings_unwrap_module_function(self):
        src = b"{ pkgs, ... }:\nlet x = 1; in\nwith pkgs; { a.b = x; }\n"
        paths = [p for p, _ in nixedit.bindings(nixedit.parse(src))]
        self.assertEqual(paths, [("a", "b")])

    def test_parse_error(self):
        with self.assertRaises(nixedit.EditError):
            nixedit.parse(b"{ a = ; }")


class FixCase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = self.tmp.name
        self.flake = os.path.join(self.root, "etc/nixos")
        os.makedirs(self.flake)
        self.env = fixes.Env(context="flake", root=self.root, flake=self.flake)

    def write_flake(self, data=FLAKE):
        with open(os.path.join(self.flake, "flake.nix"), "wb") as f:
            f.write(data)

    def read_flake(self):
        with open(os.path.join(self.flake, "flake.nix"), "rb") as f:
            return f.read()

    def run_fixes(self, *ids, sequence=0):
        chosen = tuple(f for f in fixes.FIXES if not ids or f.id in ids)
        return fixes.run_phase(
            self.env, "pre", sequence, fixes=chosen, log=lambda _: None
        )


class TestRenamed(unittest.TestCase):
    def test_renames_every_url_form(self):
        for url, expected in (
            ("git+https://gitlab.com/garuda-linux/garuda-nix-subsystem.git?ref=stable",
             "git+https://gitlab.com/garuda-linux/garuda-nix.git?ref=stable"),
            ("git+https://gitlab.com/garuda-linux/garuda-nix-subsystem.git",
             "git+https://gitlab.com/garuda-linux/garuda-nix.git"),
            ("git+https://gitlab.com/garuda-linux/garuda-nix-subsystem?ref=v2",
             "git+https://gitlab.com/garuda-linux/garuda-nix?ref=v2"),
            ("git+ssh://git@gitlab.com/garuda-linux/garuda-nix-subsystem.git",
             "git+ssh://git@gitlab.com/garuda-linux/garuda-nix.git"),
            ("git@gitlab.com:garuda-linux/garuda-nix-subsystem.git",
             "git@gitlab.com:garuda-linux/garuda-nix.git"),
            ("gitlab:garuda-linux/garuda-nix-subsystem/stable?host=gitlab.com",
             "gitlab:garuda-linux/garuda-nix/stable?host=gitlab.com"),
        ):  # fmt: skip
            self.assertEqual(fixes.renamed(url), expected)

    def test_untouched(self):
        for url in (
            "git+https://gitlab.com/garuda-linux/garuda-nix.git?ref=stable",
            "git+https://gitlab.com/garuda-linux/garuda-nix-subsystem-extras.git",
            "git+https://gitlab.com/someone/garuda-nix-subsystem.git",
            "git+https://example.org/garuda-linux/garuda-nix-subsystem.git",
            "github:garuda-linux/garuda-nix-subsystem",
        ):
            self.assertIsNone(fixes.renamed(url))


@unittest.skipUnless(HAVE_TS, "tree-sitter-nix is not installed")
class TestRepoRenameFix(FixCase):
    OLD = b"""{
  inputs.garuda.url = "git+https://gitlab.com/garuda-linux/garuda-nix-subsystem.git?ref=stable";
  inputs.other.url = "git+https://gitlab.com/someone/garuda-nix-subsystem.git";
  outputs = _: { thing.url = "https://gitlab.com/garuda-linux/garuda-nix-subsystem"; };
}
"""

    def test_renames_only_the_garuda_input(self):
        self.write_flake(self.OLD)
        self.assertTrue(self.run_fixes("repo-rename"))
        self.assertEqual(
            self.read_flake(),
            self.OLD.replace(
                b"garuda-linux/garuda-nix-subsystem.git", b"garuda-linux/garuda-nix.git"
            ),
        )
        self.assertEqual(len(self.env.notices), 1)

    def test_backup_and_idempotent(self):
        self.write_flake(self.OLD)
        self.run_fixes("repo-rename")
        backup = os.path.join(
            self.root, fixes.STATE_DIR, "backups/repo-rename/etc/nixos/flake.nix"
        )

        with open(backup, "rb") as f:
            self.assertEqual(f.read(), self.OLD)

        fixed = self.read_flake()
        self.run_fixes("repo-rename")
        self.assertEqual(self.read_flake(), fixed)
        self.assertEqual(len(self.env.notices), 1)

    def test_skipped_once_sequence_is_reached(self):
        self.write_flake(self.OLD)
        self.run_fixes("repo-rename", sequence=1)
        self.assertEqual(self.read_flake(), self.OLD)

    def test_gitlab_inputs_keep_their_fetcher(self):
        self.write_flake()
        self.assertTrue(self.run_fixes())
        out = self.read_flake()
        self.assertIn(b'inputs.old.url = "gitlab:garuda-linux/garuda-nix";', out)
        self.assertIn(b'garuda.url = "gitlab:garuda-linux/garuda-nix/stable"', out)
        self.assertIn(b'url = "gitlab:someone/else/main"', out)
        self.assertIn(b"# keep me", out)
        self.assertEqual(len(self.env.notices), 1)

    def test_every_template_ref_ends_at_the_new_repo(self):
        for ref, expected in (
            ("gitlab:garuda-linux/garuda-nix/stable",
             "gitlab:garuda-linux/garuda-nix/stable"),
            ("gitlab:garuda-linux/garuda-nix-subsystem/stable",
             "gitlab:garuda-linux/garuda-nix/stable"),
            ("gitlab:garuda-linux/garuda-nix-subsystem",
             "gitlab:garuda-linux/garuda-nix"),
            ("git+https://gitlab.com/garuda-linux/garuda-nix-subsystem.git?ref=stable",
             "git+https://gitlab.com/garuda-linux/garuda-nix.git?ref=stable"),
        ):  # fmt: skip
            self.write_flake(b'{ inputs = { garuda.url = "%s"; }; }\n' % ref.encode())
            self.assertTrue(self.run_fixes())
            self.assertEqual(self.read_flake().split(b'"')[1].decode(), expected)

    def test_no_flake(self):
        self.assertTrue(self.run_fixes())
        self.assertEqual(self.env.notices, [])

    def test_broken_flake_is_reported(self):
        self.write_flake(b'{ inputs.a.url = "gitlab:garuda-linux/garuda-nix"; ')
        self.assertFalse(self.run_fixes())


class TestRunPhase(FixCase):
    def fix(self, **kwargs):
        calls = []
        defaults = {
            "id": "t",
            "seq": 2,
            "phase": "pre",
            "contexts": ("flake",),
            "check": lambda env: True,
            "apply": lambda env: calls.append(env.context),
            "notice": "done",
        }
        defaults.update(kwargs)
        return fixes.Fix(**defaults), calls

    def run_fix(self, fix, sequence=0, phase="pre"):
        return fixes.run_phase(
            self.env, phase, sequence, fixes=(fix,), log=lambda _: None
        )

    def test_applies(self):
        fix, calls = self.fix()
        self.assertTrue(self.run_fix(fix))
        self.assertEqual(calls, ["flake"])
        self.assertEqual(self.env.notices, ["done"])

    def test_skips_when_sequence_reached(self):
        fix, calls = self.fix()
        self.run_fix(fix, sequence=2)
        self.assertEqual(calls, [])

    def test_seq_zero_always_runs(self):
        fix, calls = self.fix(seq=0)
        self.run_fix(fix, sequence=99)
        self.assertEqual(calls, ["flake"])

    def test_skips_other_phase_and_context(self):
        fix, calls = self.fix(contexts=("host",))
        self.run_fix(fix)
        fix2, calls2 = self.fix()
        self.run_fix(fix2, phase="post")
        self.assertEqual(calls + calls2, [])

    def test_check_false(self):
        fix, calls = self.fix(check=lambda env: False)
        self.assertTrue(self.run_fix(fix))
        self.assertEqual(calls, [])
        self.assertEqual(self.env.notices, [])

    def test_failure_does_not_raise(self):
        def boom(env):
            raise nixedit.Unavailable("no tree-sitter")

        fix, _ = self.fix(check=boom)
        self.assertFalse(self.run_fix(fix))
        self.assertEqual(self.env.notices, [])

    def test_registry_is_consistent(self):
        ids = [f.id for f in fixes.FIXES]
        self.assertEqual(len(ids), len(set(ids)))

        for f in fixes.FIXES:
            self.assertIn(f.phase, ("pre", "post"))
            self.assertLessEqual(f.seq, fixes.CURRENT_SEQUENCE)
            self.assertTrue(set(f.contexts) <= set(fixes.ALL))

        self.assertEqual(max(f.seq for f in fixes.FIXES), fixes.CURRENT_SEQUENCE)


class TestRunner(FixCase):
    def test_detect_context(self):
        self.assertEqual(
            runner.detect_context({"GNS_FROM_HOST": "true"}, lambda p: True), "host"
        )
        self.assertEqual(runner.detect_context({}, lambda p: True), "managed")
        self.assertEqual(runner.detect_context({}, lambda p: False), "flake")

    def test_sequence_roundtrip(self):
        self.assertEqual(runner.read_sequence(self.root), 0)
        runner.write_sequence(self.root, 3)
        self.assertEqual(runner.read_sequence(self.root), 3)

    def test_sequence_garbage_counts_as_zero(self):
        path = os.path.join(self.root, runner.SEQUENCE_FILE)
        os.makedirs(os.path.dirname(path))

        with open(path, "w") as f:
            f.write("nonsense\n")

        self.assertEqual(runner.read_sequence(self.root), 0)

    def test_clean_log_line(self):
        self.assertEqual(
            runner.clean_log_line(
                b"\r\x1b[2Kspin 1\r\x1b[2K\x1b[1;32m>>\x1b[0m done\r"
            ),
            b">> done",
        )

    def test_gns_backend_prefers_wrapped_binary(self):
        cmd, env = runner.gns_backend({"GNS_UPDATE_BIN": "/x/gns-update", "A": "1"})
        self.assertEqual(cmd, ["/x/gns-update"])
        self.assertEqual(env["A"], "1")

    def test_clone_env(self):
        repo = os.path.join(self.root, "repo")
        os.makedirs(os.path.join(repo, "lib"))

        with open(os.path.join(repo, "lib/garuda-lib.nix"), "w") as f:
            f.write("{\n  # Subsystem version\n  version = 7;\n}\n")

        answers = {"HEAD": "abc\n", "--abbrev-ref": "stable\n"}
        env = runner.clone_env(
            {"X": "1"},
            repo=repo,
            run=lambda cmd, text: (
                answers[cmd[-2]] if cmd[-2] == "--abbrev-ref" else answers["HEAD"]
            ),
        )
        self.assertEqual(env["GNS_VERSION"], "7")
        self.assertEqual(env["GNS_SELF"], f"git+{runner.REPO}?ref=stable&rev=abc")
        self.assertEqual(env["X"], "1")

    def test_clone_env_without_version(self):
        repo = os.path.join(self.root, "repo")
        os.makedirs(os.path.join(repo, "lib"))

        with open(os.path.join(repo, "lib/garuda-lib.nix"), "w") as f:
            f.write("{ }\n")

        env = runner.clone_env({}, repo=repo, run=lambda cmd, text: "x\n")
        self.assertNotIn("GNS_VERSION", env)

    def test_clone_env_repo_override(self):
        repo = os.path.join(self.root, "repo")
        os.makedirs(os.path.join(repo, "lib"))

        with open(os.path.join(repo, "lib/garuda-lib.nix"), "w") as f:
            f.write("{\n  version = 2;\n}\n")

        answers = {"HEAD": "abc\n", "--abbrev-ref": "lima-test\n"}
        env = runner.clone_env(
            {"GARUDA_UPDATE_REPO": "file:///mnt/src"},
            repo=repo,
            run=lambda cmd, text: (
                answers[cmd[-2]] if cmd[-2] == "--abbrev-ref" else answers["HEAD"]
            ),
        )
        self.assertEqual(env["GNS_SELF"], "git+file:///mnt/src?ref=lima-test&rev=abc")

    def update(self, rcs, sequence=None):
        if sequence is not None:
            runner.write_sequence(self.root, sequence)

        calls = []
        rcs = list(rcs)

        def call(cmd, **kwargs):
            calls.append(cmd)

            if cmd[0] == "git":
                return 0

            return rcs.pop(0)

        rc = runner.update("flake", self.flake, environ={}, call=call, root=self.root)
        return rc, calls

    def test_flake_update_success_bumps_sequence(self):
        rc, calls = self.update([0, 0])
        self.assertEqual(rc, 0)
        self.assertEqual(calls[0], ["nix", "flake", "update", "--flake", self.flake])
        self.assertEqual(
            calls[1], ["nh", "os", "switch", "--bypass-root-check", self.flake]
        )
        self.assertEqual(runner.read_sequence(self.root), fixes.CURRENT_SEQUENCE)

    def test_flake_update_failure_keeps_sequence(self):
        rc, _ = self.update([0, 3])
        self.assertEqual(rc, 3)
        self.assertEqual(runner.read_sequence(self.root), 0)

    def test_flake_update_stops_after_failed_input_update(self):
        rc, calls = self.update([1])
        self.assertEqual(rc, 1)
        self.assertEqual(len(calls), 1)

    def test_managed_backend_failure_changes_nothing(self):
        self.write_flake()
        calls = []

        def backend(environ):
            raise subprocess.CalledProcessError(128, ["git", "rev-parse", "HEAD"])

        rc = runner.update(
            "managed",
            self.flake,
            environ={},
            call=lambda cmd, **kw: calls.append(cmd) or 0,
            root=self.root,
            backend=backend,
        )
        self.assertEqual(rc, 1)
        self.assertEqual(calls, [])
        self.assertEqual(self.read_flake(), FLAKE)
        self.assertEqual(runner.read_sequence(self.root), 0)

    def test_managed_runs_backend_after_fixes(self):
        calls = []
        rc = runner.update(
            "managed",
            self.flake,
            environ={},
            call=lambda cmd, **kw: calls.append((cmd, kw["env"])) or 0,
            root=self.root,
            backend=lambda environ: (["gns-update"], {"A": "1"}),
        )
        self.assertEqual(rc, 0)
        self.assertEqual(calls, [(["gns-update"], {"A": "1"})])
        self.assertEqual(runner.read_sequence(self.root), fixes.CURRENT_SEQUENCE)


if __name__ == "__main__":
    unittest.main()
