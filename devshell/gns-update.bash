set -e

unset LD_PRELOAD LD_LIBRARY_PATH

if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;31mError: Something went wrong! (v1 tag) ❌\033[0m";
    exit 1
fi

FROM_HOST="${GNS_FROM_HOST:-false}"

if [ "$FROM_HOST" == "true" ]; then
    echo -e "\033[1;31mError: The garuda-nix-subsystem package is too out of date to update GNS. ❌\033[0m";
    exit 1
fi

echo -e "\033[1;33m-->\033[1;34m Migrating to updater v2 🍵\033[0m"
nix run --accept-flake-config gitlab:garuda-linux/garuda-nix-subsystem/v2?dir=internal/updater#nix -- develop --refresh --accept-flake-config gitlab:garuda-linux/garuda-nix-subsystem/v2#gns-update -c "gns-update"
