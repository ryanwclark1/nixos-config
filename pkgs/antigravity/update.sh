#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix
set -eu -o pipefail

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
infoFile="$scriptDir/sources.json"

# The Antigravity Hub (Agent Manager) latest release is discovered from the
# hub updater's /releases endpoint (newest first), matching what the official
# download page uses. The older antigravity-auto-updater /api/update endpoint
# lags behind the public release channel, so it is no longer used here.
RELEASES_URL="https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/releases"
STORAGE_BASE="https://storage.googleapis.com/antigravity-public/antigravity-hub"

usage() { echo "Usage: $0 [--check-only]" >&2; }

CHECK_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --check-only) CHECK_ONLY=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

currentVersion=$(jq -r '.version' "$infoFile" 2>/dev/null || echo "0.0.0")

# nix system -> { storage path platform, archive extension }
declare -A storagePlatform=(
  [x86_64-linux]="linux-x64"
  [aarch64-linux]="linux-arm"
  [x86_64-darwin]="darwin-x64"
  [aarch64-darwin]="darwin-arm"
)
declare -A archiveExt=(
  [x86_64-linux]="tar.gz"
  [aarch64-linux]="tar.gz"
  [x86_64-darwin]="zip"
  [aarch64-darwin]="zip"
)

echo "Fetching latest Antigravity Hub release..."
releases=$(curl -fsSL "$RELEASES_URL")
latestVersion=$(echo "$releases" | jq -r '.[0].version')
executionId=$(echo "$releases" | jq -r '.[0].execution_id' | tr -d '/')

if [[ -z "$latestVersion" || "$latestVersion" == "null" || -z "$executionId" || "$executionId" == "null" ]]; then
  echo "Error: Could not determine latest version from $RELEASES_URL" >&2
  exit 1
fi

echo "  Latest: $latestVersion (build $executionId), current: $currentVersion"

if [[ "$latestVersion" == "$currentVersion" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

if [[ "$CHECK_ONLY" == "true" ]]; then
  echo "Update available: $currentVersion -> $latestVersion"
  exit 0
fi

declare -A updates=()
for platform in "${!storagePlatform[@]}"; do
  p="${storagePlatform[$platform]}"
  ext="${archiveExt[$platform]}"
  url="${STORAGE_BASE}/${latestVersion}-${executionId}/${p}/Antigravity.${ext}"

  echo "  Prefetching $platform..."
  sha256_base32=$(nix-prefetch-url "$url" --name "Antigravity-${p}.${ext}" 2>/dev/null)
  sha256_hex=$(nix-hash --type sha256 --to-base16 "$sha256_base32")
  updates[$platform]="{\"url\":\"$url\",\"sha256\":\"$sha256_hex\"}"
done

echo "Updating $infoFile to version $latestVersion..."
jq -n \
  --arg ver "$latestVersion" \
  --arg vver "$latestVersion" \
  --arg x64l "${updates[x86_64-linux]}" \
  --arg arml "${updates[aarch64-linux]}" \
  --arg x64d "${updates[x86_64-darwin]}" \
  --arg armd "${updates[aarch64-darwin]}" \
  '{
    version: $ver,
    vscodeVersion: $vver,
    sources: {
      "x86_64-linux": ($x64l | fromjson),
      "aarch64-linux": ($arml | fromjson),
      "x86_64-darwin": ($x64d | fromjson),
      "aarch64-darwin": ($armd | fromjson)
    }
  }' > "$infoFile"

echo "✅ Updated to $latestVersion"
