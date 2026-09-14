{ pkgs }:
{
  monthly-release = pkgs.writeShellScriptBin "monthly-release" ''
    set -euo pipefail
    PREV_TAG=""
    NEW_TAG=""
    OUTPUT=""
    FLAKE_LOCK="flake.lock"
    GIT_RANGE=""

    usage() {
      echo "Usage: monthly-release [--prev-tag TAG] [--new-tag TAG] [--output FILE] [--flake-lock FILE] [--git-range RANGE]"
    }

    while [ $# -gt 0 ]; do
      case "$1" in
        --prev-tag) PREV_TAG="$2"; shift 2 ;;
        --new-tag) NEW_TAG="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --flake-lock) FLAKE_LOCK="$2"; shift 2 ;;
        --git-range) GIT_RANGE="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown arg: $1" >&2; usage >&2; exit 1 ;;
      esac
    done

    if [ -z "$GIT_RANGE" ]; then
      if [ -z "$PREV_TAG" ]; then
        PREV_TAG="$(git tag --list 'monthly-*' --sort=-v:refname | head -n1 || true)"
        [ -n "$PREV_TAG" ] || PREV_TAG="stable"
      fi
      if [ -z "$NEW_TAG" ]; then
        NEW_TAG="monthly-$(date +%Y-%m)"
      fi
      if git rev-parse "$PREV_TAG" >/dev/null 2>&1; then
        GIT_RANGE="$PREV_TAG..HEAD"
      else
        GIT_RANGE="HEAD"
      fi
    fi
    [ -n "$NEW_TAG" ] || NEW_TAG="monthly-$(date +%Y-%m)"

    {
      echo "# $NEW_TAG"
      echo
      echo "## Changes (excluding flake bumps)"
      echo
      if ! git log --no-merges --pretty='- %h %s (%an)' "$GIT_RANGE" --invert-grep --grep='^chore(flake.lock)'; then
        echo "- (no changes)"
      fi
      echo
      echo "## Flake inputs"
      echo
      ${pkgs.jq}/bin/jq -r '.nodes | to_entries[] | select(.value.locked) | "- \(.key): \(.value.locked.rev // "unknown") (\(.value.locked.url // .value.original.url // "?"))"' "$FLAKE_LOCK" | sort -u
    } | {
      if [ -n "$OUTPUT" ]; then cat > "$OUTPUT"; else cat; fi
    }
  '';
}
