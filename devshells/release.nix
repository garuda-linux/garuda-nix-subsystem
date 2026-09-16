{ pkgs }:
let
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

  build-tagged-isos = ''
    nix build .#internal.iso-dr460nized -o result-dr460nized
    nix build .#internal.iso-mokka -o result-mokka
    mkdir -p tagged-isos
    for r in result-dr460nized result-mokka; do
      edition="''${r#result-}"
      for iso in "$r"/iso/*.iso; do
        cp "$iso" "tagged-isos/garuda-nix-$edition-$TAG_NAME-x86_64-linux.iso"
      done
    done
  '';

  deploy-scp = src: ''
    chmod 600 "$DEPLOY_KEY"
    nix shell nixpkgs#openssh -c scp -B -P "''${DEPLOY_PORT:-270}" -i "$DEPLOY_KEY" \
      -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ${src} "$DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH/"
  '';

  release-iso = pkgs.writeShellScriptBin "release-iso" ''
    set -euo pipefail
    : "''${TAG_NAME:?TAG_NAME must be set}"
    ${build-tagged-isos}
    ls -la tagged-isos
    git tag -f "$TAG_NAME"
    # Remove the v2 tag once garuda-nix-subsystem no longer needs it
    git tag -f v2
    git push --atomic -f $CI_REPOSITORY_URL "$TAG_NAME" v2 HEAD:refs/heads/stable
    ${deploy-scp "tagged-isos/*.iso"}
  '';

  release-monthly = pkgs.writeShellScriptBin "release-monthly" ''
    set -euo pipefail
    : "''${TAG_NAME:?TAG_NAME must be set}"
    ${build-tagged-isos}
    git fetch --tags "$CI_REPOSITORY_URL"
    MONTHLY_TAG="monthly-$(date +%Y-%m)"
    PREV_TAG="$(git tag --list 'monthly-*' --sort=-v:refname | head -n1 || true)"
    ${monthly-release}/bin/monthly-release --prev-tag "$PREV_TAG" --new-tag "$MONTHLY_TAG" --output CHANGELOG.md
    cat CHANGELOG.md
    git tag "$MONTHLY_TAG"
    git push "$CI_REPOSITORY_URL" "$MONTHLY_TAG"
    for iso in tagged-isos/*-"$TAG_NAME"-*.iso; do
      cp "$iso" "tagged-isos/$(basename "$iso" | sed "s/-$TAG_NAME-/-$MONTHLY_TAG-/")"
    done
    ${deploy-scp ''tagged-isos/*-"$MONTHLY_TAG"-*.iso CHANGELOG.md''}
  '';
in
{
  inherit monthly-release release-iso release-monthly;
  shell = pkgs.mkShell {
    packages = [
      monthly-release
      release-iso
      release-monthly
      pkgs.jq
    ];
  };
}
