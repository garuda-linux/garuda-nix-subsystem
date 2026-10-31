#!/usr/bin/env bash
# Runs the update for one scenario and checks the result. Exits 1 on any failure.
# Usage (as root): check.sh SCENARIO, the scenarios are listed in README.md
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

scenario=${1:?usage: check.sh SCENARIO}
FAILED=0
out=$(mktemp)

# Read before the update, /mnt/src is briefly unmounted by the switch.
# Used by check_fixes in common.sh.
# shellcheck disable=SC2034
SEQUENCE=$(current_sequence)
SEQ_FILE=/$STATE_DIR/intervention_sequence

# Runs run-update.sh, RC holds its exit code
run_update() {
  RC=0
  bash "$HARNESS/run-update.sh" "${1:-$scenario}" "${@:2}" 2>&1 | tee "$out" || RC=${PIPESTATUS[0]}
}

expect_rc() {
  if [ "$RC" = "$1" ]; then pass "garuda-update exited $1"; else fail "garuda-update exited $RC, expected $1"; fi
}

expect_failed_rc() {
  if [ "$RC" != 0 ]; then pass "garuda-update failed ($RC)"; else fail "garuda-update exited 0, expected a failure"; fi
}

case "$scenario" in
flake | fallback | managed)
  lock_before=$(sha256sum /etc/nixos/flake.lock)
  run_update
  expect_rc 0

  # No generation check: without new commits on stable the closure stays the same
  step "Checking the result"
  check_fixes / /etc/nixos
  expect "the update backend finished" grep -q "System updated!" "$out"
  expect "update notices were printed" grep -q "Update notices" "$out"

  if [ "$scenario" = managed ]; then
    # gns-update uses nh os boot, the new generation becomes active on reboot
    expect "/etc/nixos has the gns-update commit" \
      sh -c "git -C /etc/nixos log --format=%s | grep -qx gns-update"

    # The shared home mounts @home from this UUID on the next boot
    btrfs_uuid=$(blkid -L garuda-host | xargs blkid -s UUID -o value)
    expect "garuda-managed.json keeps the host btrfs UUID" \
      grep -q "\"uuid\": \"$btrfs_uuid\"" /etc/nixos/garuda-managed.json
  else
    expect "/etc/nixos has the fix commit" \
      sh -c "git -C /etc/nixos log --format=%s | grep -qx 'fix: apply garuda-update fixes'"

    # Nothing to commit when the update left flake.lock unchanged
    if [ "$(sha256sum /etc/nixos/flake.lock)" != "$lock_before" ]; then
      expect "/etc/nixos has the flake.lock commit" \
        sh -c "git -C /etc/nixos log --format=%s | grep -q '^chore(flake.lock): '"
    else
      pass "flake.lock did not change, no flake.lock commit expected"
    fi

    expect "the system profile is the running system" \
      test "$(readlink -f /run/current-system)" = "$(readlink -f /nix/var/nix/profiles/system)"
  fi

  if [ "$scenario" = fallback ]; then
    expect "the git clone fallback was used" grep -q "trying git instead" "$out"
  fi
  ;;
host | host-fallback)
  run_update
  expect_rc 0

  step "Checking the result"
  uuid=$(findmnt -n -o UUID /)
  mnt=$(mktemp -d)
  mount -o subvol=@nix-subsystem "UUID=$uuid" "$mnt"
  trap 'umount "$mnt"; rmdir "$mnt"' EXIT
  check_fixes "$mnt" "$mnt/etc/nixos"
  expect "the update backend finished" grep -q "System updated!" "$out"
  expect "update notices were printed" grep -q "Update notices" "$out"
  expect "the GRUB entry exists" test -x /etc/grub.d/25-garudanix

  if [ "$scenario" = host-fallback ]; then
    expect "the runner ran from a git clone" grep -q "Running the runner from a git clone" "$out"
    expect "the fixes had tree-sitter-nix" sh -c "! grep -q 'tree-sitter-nix is not available' '$out'"
  fi
  ;;
fix-fails)
  # git+https with the old repo name (the GitLab redirect keeps it working),
  # and flake.nix can not be written, so the fix fails but the update works.
  step "Setting up: old repo name over git+https, flake.nix immutable"
  sed -i "s|$OLD_GARUDA_URL|$INSTALL_GARUDA_URL|" /etc/nixos/flake.nix
  commit_all /etc/nixos "Old repo name over git+https"
  chattr +i /etc/nixos/flake.nix
  run_update flake
  chattr -i /etc/nixos/flake.nix

  step "Checking the first run"
  expect_rc 0
  expect "the failed fix was reported" grep -q "warning: fix repo-rename was skipped" "$out"
  expect "flake.nix still has the old repo name" grep -qF "$INSTALL_GARUDA_URL" /etc/nixos/flake.nix
  expect "intervention_sequence was not written" test ! -e "$SEQ_FILE"
  expect "no notice for the failed fix" sh -c "! grep -q 'now points to garuda-nix' '$out'"
  expect "the update backend finished" grep -q "System updated!" "$out"

  step "Second run, flake.nix writable again"
  run_update flake
  expect_rc 0
  expect "the fix is applied on the next run" grep -q "Applied fix repo-rename" "$out"
  expect "flake.nix uses the new repo name" grep -qF "$NEW_GARUDA_URL" /etc/nixos/flake.nix
  expect "intervention_sequence is $SEQUENCE" grep -qx "INTERVENTION_SEQUENCE=$SEQUENCE" "$SEQ_FILE"
  ;;
rebuild-fails)
  step "Setting up: a configuration that fails to evaluate"
  sed -i 's|^}$|  assertions = [ { assertion = false; message = "limatest: broken configuration"; } ];\n}|' \
    /etc/nixos/configuration.nix
  grep -q "limatest: broken configuration" /etc/nixos/configuration.nix
  commit_all /etc/nixos "Broken configuration"

  system_before=$(readlink -f /run/current-system)
  run_update flake

  step "Checking the result"
  expect_failed_rc
  expect "the rebuild error is shown" grep -q "limatest: broken configuration" "$out"
  expect "no success message" sh -c "! grep -q 'System updated!' '$out'"
  expect "intervention_sequence was not written" test ! -e "$SEQ_FILE"
  expect "the running system is unchanged" test "$(readlink -f /run/current-system)" = "$system_before"
  expect "the pre fixes stay applied" grep -qF "\"$RENAMED_GARUDA_URL\"" /etc/nixos/flake.nix
  expect "no flake.lock commit" \
    sh -c "! git -C /etc/nixos log --format=%s | grep -q '^chore(flake.lock): '"
  ;;
fetch-fails)
  flake_before=$(sha256sum /etc/nixos/flake.nix)
  system_before=$(readlink -f /run/current-system)
  LIMATEST_REPO=file:///nonexistent run_update flake

  step "Checking the result"
  expect_rc 1
  expect "the abort is reported" grep -q "Unable to fetch garuda-update from file:///nonexistent" "$out"
  expect "the git clone was tried" grep -q "trying git instead" "$out"
  expect "flake.nix is unchanged" test "$(sha256sum /etc/nixos/flake.nix)" = "$flake_before"
  expect "no backups were written" test ! -e "/$STATE_DIR/backups"
  expect "intervention_sequence was not written" test ! -e "$SEQ_FILE"
  expect "the running system is unchanged" test "$(readlink -f /run/current-system)" = "$system_before"
  ;;
rollback)
  run_update flake
  expect_rc 0
  gen=$(generation)

  step "Rolling back from generation $gen"
  run_update flake --rollback
  expect_rc 0
  expect "the system profile is generation $((gen - 1))" test "$(generation)" = "$((gen - 1))"
  expect "the running system is the rolled back generation" \
    test "$(readlink -f /run/current-system)" = "$(readlink -f /nix/var/nix/profiles/system)"
  ;;
modules)
  # The garuda input points at the snapshot, so the update builds the current
  # modules. The old-URL fixes are covered by the flake scenario.
  step "Setting up: garuda input from the snapshot"
  sed -i "s|$OLD_GARUDA_URL|$SRC_FLAKE|" /etc/nixos/flake.nix
  grep -qF "$SRC_FLAKE" /etc/nixos/flake.nix
  commit_all /etc/nixos "Garuda input from the snapshot"

  gen_before=$(generation)
  run_update flake
  expect_rc 0

  step "Checking the result"
  expect "the update backend finished" grep -q "System updated!" "$out"
  expect "flake.lock has the snapshot" grep -q "\"ref\": \"$SRC_REF\"" /etc/nixos/flake.lock
  expect "a new generation was built" test "$(generation)" -gt "$gen_before"
  expect "the system profile is the running system" \
    test "$(readlink -f /run/current-system)" = "$(readlink -f /nix/var/nix/profiles/system)"
  expect "the system Nix is Lix" sh -c "/run/current-system/sw/bin/nix --version | grep -q Lix"
  expect "no evaluation warnings" sh -c "! grep -q 'evaluation warning' '$out'"
  ;;
sudo-setenv)
  # The launcher re-runs itself with sudo --preserve-env=... Rules for the command
  # ALL imply SETENV, so the case without it is a rule for the launcher alone.
  step "Building garuda-update-launcher from the snapshot"
  launcher=$("${NIX[@]}" build --no-link --print-out-paths "$SRC_FLAKE#garuda-update-launcher")/bin/garuda-update

  id -u limatest >/dev/null 2>&1 || useradd -m limatest

  sudoers=$(mktemp)
  cat /etc/sudoers >"$sudoers"
  echo "limatest ALL=(root) NOPASSWD: $launcher" >>"$sudoers"
  chmod 0440 "$sudoers"
  visudo -cf "$sudoers" >/dev/null
  mount --bind "$sudoers" /etc/sudoers
  trap 'umount /etc/sudoers' EXIT

  # Documented in docs/src/updating.md: sudo refuses the launcher while a
  # GARUDA_* variable is set. The repo does not exist, so nothing gets updated
  # if the variables arrive after all.
  step "Running the launcher as limatest with GARUDA_* set (rule without SETENV)"
  runuser -u limatest -- env GARUDA_UPDATE_REPO=file:///nonexistent GARUDA_UPDATE_NO_NIX=1 \
    "$launcher" --flake /nonexistent-flake 2>&1 | tee "$out" || true
  expect "sudo refuses the GARUDA_* variables" \
    grep -q "not allowed to set the following environment variables: GARUDA_UPDATE_NO_NIX, GARUDA_UPDATE_REPO" "$out"

  # Without a variable the launcher has to get through sudo. No network, so it
  # can not fetch the updater and stops before changing anything.
  step "Running the launcher as limatest without GARUDA_* (no network)"
  system_before=$(readlink -f /run/current-system)
  RC=0
  unshare --net runuser -u limatest -- "$launcher" --flake /nonexistent-flake 2>&1 | tee "$out" ||
    RC=${PIPESTATUS[0]}

  expect_rc 1
  expect "sudo accepts the launcher" sh -c "! grep -q 'not allowed' '$out'"
  expect "the launcher ran as root up to the fetch" \
    grep -q "Unable to fetch garuda-update from https://gitlab.com/garuda-linux/garuda-nix.git (stable)" "$out"
  expect "the running system is unchanged" test "$(readlink -f /run/current-system)" = "$system_before"
  ;;
*)
  echo "unknown scenario: $scenario" >&2
  exit 1
  ;;
esac

rm -f "$out"

if [ "$FAILED" = 0 ]; then
  echo -e "\n\033[1;32mPASS: $scenario\033[0m"
else
  echo -e "\n\033[1;31mFAIL: $scenario\033[0m"
fi
exit "$FAILED"
