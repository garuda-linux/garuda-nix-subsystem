#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FILES=("$@")
if [[ ${#FILES[@]} -eq 0 ]]; then
  FILES=(
    "$ROOT/packages/firedragon-bin/version.json"
    "$ROOT/packages/firedragon-catppuccin-bin/version.json"
    "$ROOT/packages/beautyline-icons/version.json"
    "$ROOT/packages/dr460nized-kde-theme/version.json"
  )
fi

refresh_firedragon() {
  local file="$1" variant project_id base v
  
  variant="$(basename "$(dirname "$file")")" # firedragon-bin | firedragon-catppuccin-bin
  project_id="75420733"
  v="$(jq -r '.version' "$file")"

  if [[ "$variant" == "firedragon-catppuccin-bin" ]]; then
    base="firedragon-catppuccin-v${v}"
  else
    base="firedragon-v${v}"
  fi
  
  declare -A fnames=(
    ["aarch64-linux"]="${base}.linux-arm64.tar.xz"
    ["x86_64-linux"]="${base}.linux-x64.tar.xz"
  )

  local arch url hash json='{"version":"'"$v"'","sources":{}}'
  for arch in aarch64-linux x86_64-linux; do
    url="https://gitlab.com/api/v4/projects/${project_id}/packages/generic/firedragon/${v}/${fnames[$arch]}"
    hash="$(nix-prefetch-url --type sha256 "$url" 2>/dev/null | tr -d '[:space:]' | tail -n1)"
    json="$(jq --arg a "$arch" --arg u "$url" --arg s "$hash" \
      '.sources[$a] = {"url": $u, "sha256": $s}' <<<"$json")"
  done
  
  tmp="$(mktemp)"
  jq . <<<"$json" >"$tmp"
  mv "$tmp" "$file"
  
  echo "refreshed $file -> $v"
}

refresh_gitlab_head() {
  local file="$1" group owner repo rev date short hash stamp out

  case "$file" in
    *beautyline-icons*) group="garuda-linux" owner="themes-and-settings/artwork" repo="beautyline" ;;
    *dr460nized-kde-theme*) group="garuda-linux" owner="themes-and-settings/settings" repo="garuda-dr460nized" ;;
    *) echo "unknown git package: $file" >&2; return 1 ;;
  esac
  rev="$(jq -r '.rev' "$file")"

  out="$(nix-prefetch-git --url "https://gitlab.com/${group}/${owner}/${repo}" --rev "$rev" --quiet)"
  hash="$(jq -r '.hash' <<<"$out")"
  date="$(jq -r '.date' <<<"$out")"
  short="${rev:0:7}"
  stamp="$(date -u -d "$date" +%Y%m%d%H%M%S)"
  
  jq --arg v "unstable-${stamp}-${short}" --arg r "$rev" --arg h "$hash" \
    '.version=$v | .rev=$r | .hash=$h' "$file" >"$file.tmp" && mv "$file.tmp" "$file"
  
  echo "refreshed $file -> $rev"
}

for f in "${FILES[@]}"; do
  # Renovate passes repo-relative paths: normalise to absolute.
  [[ "$f" = /* ]] || f="$ROOT/$f"
  case "$f" in
    *firedragon-bin/version.json | *firedragon-catppuccin-bin/version.json) refresh_firedragon "$f" ;;
    *beautyline-icons/version.json | *dr460nized-kde-theme/version.json) refresh_gitlab_head "$f" ;;
    *) echo "skip: $f" ;;
  esac
done
