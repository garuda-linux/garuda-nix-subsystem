#!/usr/bin/env bash
# Runs the updater from the source snapshot, the same way users get it.
# Usage (as root): run-update.sh flake|fallback|managed|host|host-fallback [garuda-update args]
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

scenario=${1:?usage: run-update.sh flake|fallback|managed|host|host-fallback}
shift

# Users rarely run garuda-update from /
cd /tmp || exit 1

case "$scenario" in
flake | managed | fallback)
  step "Building garuda-update-launcher from the snapshot"
  launcher=$("${NIX[@]}" build --no-link --print-out-paths --refresh "$SRC_FLAKE#garuda-update-launcher")

  no_nix=
  if [ "$scenario" = fallback ]; then no_nix=1; fi

  # gns-update writes the host btrfs UUID into garuda-managed.json, by default
  # the UUID of /. On a subsystem / is on that btrfs, in this VM it is a
  # separate ext4 disk, so pass the UUID of the btrfs disk like the host would.
  btrfs_uuid=

  if [ "$scenario" = managed ]; then btrfs_uuid=$(blkid -L garuda-host | xargs blkid -s UUID -o value); fi

  # LIMATEST_REPO points the launcher at another repository (fetch-fails)
  exec env GARUDA_UPDATE_REPO="${LIMATEST_REPO:-$SRC_URL}" GARUDA_UPDATE_REF="$SRC_REF" GARUDA_UPDATE_NO_NIX="$no_nix" \
    ${btrfs_uuid:+GNS_BTRFS_UUID="$btrfs_uuid"} "$launcher/bin/garuda-update" "$@"
  ;;
host)
  # Same as the updater script of the Arch garuda-nix-subsystem package
  exec env GNS_FROM_HOST=true GARUDA_UPDATE_REPO="$SRC_URL" \
    "${NIX[@]}" develop --refresh "$SRC_FLAKE#gns-update" -c gns-update "$@"
  ;;
host-fallback)
  # Same as the git clone fallback of the Arch package's updater
  step "Running the runner from a git clone"
  clone=$(mktemp -d)
  git clone --quiet --depth 1 --branch "$SRC_REF" "$SRC_URL" "$clone/garuda-nix"

  # shellcheck disable=SC2016
  python_env='(builtins.getFlake "nixpkgs").legacyPackages.${builtins.currentSystem}.python3.withPackages (ps: [ ps.tree-sitter ps.tree-sitter-grammars.tree-sitter-nix ])'

  exec env GNS_FROM_HOST=true GARUDA_UPDATE_REPO="$SRC_URL" \
    "${NIX[@]}" shell --impure --expr "$python_env" -c \
    python3 "$clone/garuda-nix/packages/garuda-update/runner.py" "$@"
  ;;
*)
  echo "unknown scenario: $scenario" >&2
  exit 1
  ;;
esac
