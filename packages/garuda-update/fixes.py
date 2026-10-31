"""Fixes garuda-update applies around the update.

A new fix gets seq = CURRENT_SEQUENCE + 1 (bump it), or seq = 0 to run always.
Its check must return False once the fix is applied.
"""

import os
import re
import sys
from collections.abc import Callable
from dataclasses import dataclass, field

import nixedit

CURRENT_SEQUENCE = 1
STATE_DIR = "var/lib/garuda/garuda-update"
ALL = ("host", "managed", "flake")


@dataclass
class Env:
    context: str
    root: str
    flake: str
    notices: list = field(default_factory=list)
    touched: list = field(default_factory=list)

    def read(self, path):
        with open(path, "rb") as f:
            return f.read()

    def write(self, path, data, fix_id):
        backup = os.path.join(
            self.root, STATE_DIR, "backups", fix_id, os.path.relpath(path, self.root)
        )
        os.makedirs(os.path.dirname(backup), exist_ok=True)

        with open(backup, "wb") as f:
            f.write(self.read(path))

        with open(path, "wb") as f:
            f.write(data)

        self.touched.append(path)


@dataclass(frozen=True)
class Fix:
    id: str
    seq: int
    phase: str
    contexts: tuple
    check: Callable[[Env], bool]
    apply: Callable[[Env], None]
    notice: str


RENAME_RE = re.compile(
    r"(gitlab(?:\.com[/:]|:)garuda-linux/)garuda-nix-subsystem(?=$|[./?#])"
)


def renamed(url):
    """URL of the garuda-nix-subsystem repo under its new name, else None."""
    new = RENAME_RE.sub(r"\1garuda-nix", url)

    return new if new != url else None


def input_urls(fix_id, translate):
    """check and apply of a fix that rewrites the input URLs of flake.nix."""

    def edits(env):
        path = os.path.join(env.flake, "flake.nix")

        if not os.path.isfile(path):
            return path, b"", []

        src = env.read(path)
        found = []

        for attr, value in nixedit.bindings(nixedit.parse(src)):
            url = nixedit.string_value(value)

            if attr[0] != "inputs" or attr[-1] != "url" or url is None:
                continue

            new = translate(url.text.decode())

            if new:
                found.append((url.start_byte, url.end_byte, new.encode()))

        return path, src, found

    def apply(env):
        path, src, found = edits(env)

        env.write(path, nixedit.splice(src, found), fix_id)

    return {"check": lambda env: bool(edits(env)[2]), "apply": apply}


FIXES = (
    Fix(
        id="repo-rename",
        seq=1,
        phase="pre",
        contexts=ALL,
        notice="The Garuda input in flake.nix now points to garuda-nix, the "
        "new name of the garuda-nix-subsystem repository.",
        **input_urls("repo-rename", renamed),
    ),
)


def run_phase(env, phase, sequence, fixes=FIXES, log=None):
    """Apply the pending fixes of a phase, False if one of them failed."""
    log = log or (lambda msg: print(msg, file=sys.stderr))
    ok = True

    for fix in fixes:
        if fix.phase != phase or env.context not in fix.contexts:
            continue

        if fix.seq and sequence >= fix.seq:
            continue

        try:
            if not fix.check(env):
                continue

            fix.apply(env)
        except Exception as e:  # noqa: BLE001
            log(f"warning: fix {fix.id} was skipped: {e}")
            ok = False
            continue

        log(f"Applied fix {fix.id}")
        env.notices.append(fix.notice)

    return ok
