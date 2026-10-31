# shellcheck shell=bash disable=SC2034
# Shared by the guest scripts. The host mounts the source snapshot at /mnt/src
# and this directory at /mnt/lima. limatest copies it to /run/limatest and runs
# it from there: a NixOS switch rewrites /etc/fstab and unmounts the Lima
# mounts until lima-init adds them again, which fails while a script runs from them.
set -euo pipefail

HARNESS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SRC_URL=file:///mnt/src
SRC_REF=lima-test
SRC_FLAKE="git+$SRC_URL?ref=$SRC_REF"

# The garuda input of old installs, rewritten by repo-rename
OLD_GARUDA_URL="gitlab:garuda-linux/garuda-nix-subsystem/stable"
RENAMED_GARUDA_URL="gitlab:garuda-linux/garuda-nix/stable"
# Used for the first install (GitLab redirects the old repo name), and by
# fix-fails. Makes flake.lock differ from the URL the fixes write, so the
# update has to re-lock like on real old installs.
INSTALL_GARUDA_URL="git+https://gitlab.com/garuda-linux/garuda-nix-subsystem.git?ref=${GNS_OLD_REF:-stable}"
NEW_GARUDA_URL="git+https://gitlab.com/garuda-linux/garuda-nix.git?ref=stable"

STATE_DIR=var/lib/garuda/garuda-update
LOG_FILE=/var/log/garuda/garuda-update

if [ -x /nix/var/nix/profiles/default/bin/nix ] && ! command -v nix >/dev/null; then
  PATH="/nix/var/nix/profiles/default/bin:$PATH"
fi

NIX=(nix --extra-experimental-features "nix-command flakes" --accept-flake-config)

step() {
  echo -e "\033[1;32m»\033[0m $*" >&2
}

fail() {
  echo -e "\033[1;31mFAIL:\033[0m $*" >&2
  FAILED=1
}

pass() {
  echo -e "\033[1;32mok:\033[0m $*" >&2
}

commit_all() {
  git -C "$1" -c user.name=lima -c user.email=lima@localhost commit -qam "$2"
}

expect() {
  local msg=$1
  shift

  if "$@" >/dev/null 2>&1; then pass "$msg"; else fail "$msg"; fi
}

current_sequence() {
  git --git-dir=/mnt/src show "$SRC_REF:packages/garuda-update/fixes.py" |
    sed -n 's/^CURRENT_SEQUENCE = \([0-9]*\)$/\1/p'
}

# Checks shared by every scenario. $1 is the system root, $2 the flake.
check_fixes() {
  local root=$1 flake=$2 seq=$SEQUENCE

  expect "flake.nix uses the new repo name" \
    grep -qF "\"$RENAMED_GARUDA_URL\"" "$flake/flake.nix"
  expect "flake.nix has no garuda-nix-subsystem URL left" \
    sh -c "! grep -q 'garuda-linux/garuda-nix-subsystem' '$flake/flake.nix'"
  expect "backup of repo-rename exists" \
    test -d "$root/$STATE_DIR/backups/repo-rename"
  expect "intervention_sequence is $seq" \
    grep -qx "INTERVENTION_SEQUENCE=$seq" "$root/$STATE_DIR/intervention_sequence"
  expect "log file $LOG_FILE is not empty" test -s "$LOG_FILE"
}

# Current system generation number of a profile. The link target is relative
# after nixos-rebuild, absolute after nh os rollback.
generation() {
  readlink "${1:-/nix/var/nix/profiles/system}" | sed -n 's/^\(.*\/\)\{0,1\}system-\([0-9]*\)-link$/\2/p'
}
