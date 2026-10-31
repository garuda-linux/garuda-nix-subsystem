# shellcheck shell=bash
# Lima VMs that run garuda-update from the working tree against old Garuda Nix installs.
# Packaged as the limatest devshell command.

usage() {
  cat <<'EOF'
usage: limatest <scenario> [--check] [--keep] [--reprovision]
       limatest list | stop [scenario|all] | delete [scenario|all]

Scenarios:
  flake      plain Garuda Nix flake setup (VM gns-flake)
  fallback   same VM, launcher with GARUDA_UPDATE_NO_NIX=1 (git clone path)
  managed    managed system with garuda-managed.json (VM gns-managed)
  host       Arch host with the subsystem (VM gns-arch)
  host-fallback  same VM, runner from a git clone (fallback of the Arch package)

Failure paths and launcher features, all on VM gns-flake (use --check):
  fix-fails      a fix can not write flake.nix: skipped, no sequence, applied next run
  rebuild-fails  broken configuration: update fails, sequence not written, system unchanged
  fetch-fails    launcher repo does not exist: abort, nothing changed
  rollback       update, then garuda-update --rollback goes back one generation
  sudo-setenv    sudo rule without SETENV: refused with GARUDA_* set, works without
  modules        garuda input from the snapshot: the update builds the current modules

Every run copies the working tree (tracked files, staged and unstaged) to
branch lima-test of .lima/_src.git, mounted at /mnt/src in the VM.
The first run of a VM provisions an old install and saves the Lima snapshot
old-install. Later runs restore it first. A VM without that snapshot (for
example after a failed provisioning) needs --reprovision.

Options:
  --check        run garuda-update and check the result, exit 1 on failure
  --keep         do not restore the old-install snapshot
  --reprovision  delete the VM and provision it again
EOF
}

ROOT=$(git rev-parse --show-toplevel)
export LIMA_HOME="$ROOT/.lima"
LIMA_DIR="$ROOT/internal/testing/lima"
SRC="$LIMA_HOME/_src.git"
REF=lima-test
SNAPSHOT=old-install
ALL_INSTANCES=(gns-flake gns-managed gns-arch)
HOME_DISK=gns-managed-home

instance_for() {
  case "$1" in
  flake | fallback | fix-fails | rebuild-fails | fetch-fails | rollback | sudo-setenv | modules) echo gns-flake ;;
  managed) echo gns-managed ;;
  host | host-fallback) echo gns-arch ;;
  *)
    echo "unknown scenario: $1" >&2
    return 1
    ;;
  esac
}

exists() {
  limactl list -q 2>/dev/null | grep -qx "$1"
}

running() {
  [ "$(limactl list --format '{{.Status}}' "$1" 2>/dev/null)" = Running ]
}

has_snapshot() {
  limactl snapshot list "$1" 2>/dev/null | grep -qw "$SNAPSHOT"
}

snapshot_source() {
  mkdir -p "$LIMA_HOME"

  if [ ! -d "$SRC" ]; then
    git init -q --bare "$SRC"
  fi

  # Tracked files as in the working tree, through a copy of the index.
  # git stash create fails on intent-to-add entries.
  local index tree commit
  index=$(mktemp)
  cp "$(git -C "$ROOT" rev-parse --path-format=absolute --git-path index)" "$index"
  GIT_INDEX_FILE="$index" git -C "$ROOT" add -u
  tree=$(GIT_INDEX_FILE="$index" git -C "$ROOT" write-tree)
  rm -f "$index"
  commit=$(git -C "$ROOT" commit-tree "$tree" -p HEAD -m "limatest snapshot")
  git -C "$ROOT" push -q -f --no-verify "$SRC" "$commit:refs/heads/$REF"
  echo "» Source snapshot $(git -C "$ROOT" rev-parse --short "$commit") is branch $REF in $SRC"

  local untracked
  untracked=$(git -C "$ROOT" ls-files --others --exclude-standard | grep -v '^internal/testing/lima/' || true)

  if [ -n "$untracked" ]; then
    echo "» Not in the snapshot, untracked (git add them to include them):"

    while IFS= read -r file; do echo "    $file"; done <<<"$untracked"
  fi
}

# Copy the guest scripts out of the Lima mount, see guest/common.sh
guest_sync() {
  limactl shell --workdir / "$1" sudo sh -c 'rm -rf /run/limatest && cp -r /mnt/lima/guest /run/limatest'
}

guest_run() {
  local inst=$1 script=$2
  shift 2
  guest_sync "$inst"
  limactl shell --workdir / "$inst" sudo bash "/run/limatest/$script" "$@"
}

delete_instance() {
  limactl delete -f "$1"

  if [ "$1" = gns-managed ] && [ -d "$LIMA_HOME/_disks/$HOME_DISK" ]; then
    limactl disk delete -f "$HOME_DISK"
  fi
}

provision() {
  local inst=$1 template script

  case "$inst" in
  gns-flake) template=nixos.yaml script="provision-nixos.sh flake" ;;
  gns-managed) template=nixos.yaml script="provision-nixos.sh managed" ;;
  gns-arch) template=arch.yaml script="provision-arch.sh" ;;
  esac

  local config
  config=".mounts = [
    {\"location\": \"$SRC\", \"mountPoint\": \"/mnt/src\", \"9p\": {\"cache\": \"mmap\"}},
    {\"location\": \"$LIMA_DIR\", \"mountPoint\": \"/mnt/lima\", \"9p\": {\"cache\": \"mmap\"}}
  ]"

  # Stands in for the btrfs filesystem of the Garuda host with the @home
  # subvolume, which the subsystem's shared home mounts. Formatted in the guest.
  if [ "$inst" = gns-managed ]; then
    if [ -d "$LIMA_HOME/_disks/$HOME_DISK" ]; then limactl disk delete -f "$HOME_DISK"; fi

    limactl disk create "$HOME_DISK" --size 8GiB
    config="$config | .additionalDisks = [{\"name\": \"$HOME_DISK\", \"format\": false}]"
  fi

  limactl create --tty=false --name="$inst" --set "$config" "$LIMA_DIR/$template"
  limactl start "$inst"

  # shellcheck disable=SC2086
  guest_run "$inst" $script

  limactl stop "$inst"
  limactl snapshot create "$inst" --tag "$SNAPSHOT"
  limactl start "$inst"
}

prepare() {
  local inst=$1 keep=$2 reprovision=$3

  if [ "$reprovision" = 1 ] && exists "$inst"; then
    delete_instance "$inst"
  fi

  if ! exists "$inst"; then
    provision "$inst"
  elif ! has_snapshot "$inst"; then
    # Never delete a VM on our own, the snapshot list may only look empty
    echo "» $inst has no $SNAPSHOT snapshot. Check with: limactl snapshot list $inst" >&2
    echo "» Run limatest with --reprovision to delete and provision it again." >&2
    exit 1
  elif [ "$keep" = 0 ]; then
    echo "» Restoring snapshot $SNAPSHOT of $inst"

    if running "$inst"; then limactl stop "$inst"; fi

    limactl snapshot apply "$inst" --tag "$SNAPSHOT"
    limactl start "$inst"
  elif ! running "$inst"; then
    limactl start "$inst"
  fi
}

targets() {
  if [ "${1:-all}" = all ]; then
    printf '%s\n' "${ALL_INSTANCES[@]}"
  else
    instance_for "$1"
  fi
}

case "${1:-}" in
"" | -h | --help | help)
  usage
  exit 0
  ;;
list)
  exec limactl list
  ;;
stop | delete)
  action=$1

  for inst in $(targets "${2:-all}"); do
    if ! exists "$inst"; then continue; fi

    if [ "$action" = stop ]; then
      if running "$inst"; then limactl stop "$inst"; fi
    else
      delete_instance "$inst"
    fi
  done

  exit 0
  ;;
esac

scenario=$1
shift
inst=$(instance_for "$scenario")
check=0 keep=0 reprovision=0

for arg in "$@"; do
  case "$arg" in
  --check) check=1 ;;
  --keep) keep=1 ;;
  --reprovision) reprovision=1 ;;
  *)
    usage >&2
    exit 1
    ;;
  esac
done

snapshot_source
prepare "$inst" "$keep" "$reprovision"

if [ "$check" = 1 ]; then
  guest_run "$inst" check.sh "$scenario"
  exit
fi

guest_sync "$inst"

cat <<EOF
» $inst is ready (old-install state). Inside the VM:
    sudo bash /run/limatest/run-update.sh $scenario   # run the uncommitted garuda-update
» For a checked run use "limatest $scenario --check" on the host, it restores old-install first.
EOF
exec limactl shell --workdir / "$inst"
