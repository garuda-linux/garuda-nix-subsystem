# shellcheck shell=bash
unset LD_PRELOAD LD_LIBRARY_PATH

if [ "$EUID" -ne 0 ]; then
  exec sudo --preserve-env=GARUDA_FLAKE,GARUDA_UPDATE_REF,GARUDA_UPDATE_NO_NIX,GARUDA_UPDATE_REPO "$0" "$@"
fi

if [ "${1:-}" = "--rollback" ]; then
  echo -e "\033[1;33m-->\033[1;34m Rolling back to previous generation 🍵\033[0m"
  nh os rollback --bypass-root-check
  exit 0
fi

# GARUDA_UPDATE_REPO fetches from another repository, to test uncommitted changes
REPO="${GARUDA_UPDATE_REPO:-https://gitlab.com/garuda-linux/garuda-nix.git}"
REF="${GARUDA_UPDATE_REF:-stable}"

echo -e "\033[1;33m-->\033[1;34m Fetching the latest garuda-update 🍵\033[0m"

if [ "${GARUDA_UPDATE_NO_NIX:-}" != "1" ] &&
  runner="$(nix build --extra-experimental-features "nix-command flakes" --accept-flake-config \
    --refresh --no-link --print-out-paths "git+$REPO?ref=$REF#garuda-update-runner")"; then
  exec "$runner/bin/garuda-update-runner" "$@"
fi

# Same runner without Nix, for the case that Nix itself can not fetch it
echo -e "\033[1;33m-->\033[1;34m Nix could not fetch garuda-update, trying git instead\033[0m"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if git clone --quiet --depth 1 --branch "$REF" "$REPO" "$tmp/garuda-nix"; then
  python3 "$tmp/garuda-nix/packages/garuda-update/runner.py" "$@"
  exit
fi

echo -e "\033[1;31mError: Unable to fetch garuda-update from $REPO ($REF). The system was not updated. ❌\033[0m" >&2
exit 1
