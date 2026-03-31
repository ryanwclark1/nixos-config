#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

set -euo pipefail

BASE_URL="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_PATH="$SCRIPT_DIR/manifest.json"

usage() {
  echo "Usage: $0 [--check-only]" >&2
}

CHECK_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --check-only)
      CHECK_ONLY=true
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

currentVersion=$(jq -r '.version' "$MANIFEST_PATH")
if [[ -z "$currentVersion" || "$currentVersion" == "null" ]]; then
  echo "Error: Failed to read current version from $MANIFEST_PATH" >&2
  exit 1
fi

latestVersion=$(curl -fsSL "$BASE_URL/latest")
if [[ -z "$latestVersion" ]]; then
  echo "Error: Failed to fetch latest Claude Code version" >&2
  exit 1
fi

if [[ "$latestVersion" == "$currentVersion" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

if [[ "$CHECK_ONLY" == "true" ]]; then
  echo "Update available: $currentVersion -> $latestVersion"
  exit 0
fi

tempManifest="$(mktemp)"
trap 'rm -f "$tempManifest"' EXIT

curl -fsSL "$BASE_URL/$latestVersion/manifest.json" --output "$tempManifest"

manifestVersion=$(jq -r '.version' "$tempManifest")
if [[ "$manifestVersion" != "$latestVersion" ]]; then
  echo "Error: Manifest version mismatch: expected $latestVersion, got $manifestVersion" >&2
  exit 1
fi

cp "$tempManifest" "$MANIFEST_PATH"

echo ""
echo "Updated Claude Code binary manifest"
echo "  Version: $currentVersion -> $latestVersion"
echo ""
echo "Please review the changes:"
echo "  git diff $MANIFEST_PATH"
