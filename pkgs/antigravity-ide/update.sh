#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix gnutar gzip
set -eu -o pipefail

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
infoFile="$scriptDir/sources.json"

# The Antigravity IDE latest release is discovered from the IDE updater's
# /releases endpoint (newest first), the same source the official download page
# uses. This avoids the staged-rollout lag of the /api/update/.../stable/latest
# endpoint. Downloads + sha256 come from the edgedl CDN; the (build-significant)
# VS Code version is read from the downloaded archive's product.json.
RELEASES_URL="https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/releases"
EDGEDL_BASE="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable"

usage() { echo "Usage: $0 [--check-only] [version]" >&2; }

CHECK_ONLY=false
PIN_VERSION=""
for arg in "$@"; do
  case "$arg" in
    --check-only) CHECK_ONLY=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      usage
      exit 1
      ;;
    *) PIN_VERSION="$arg" ;;
  esac
done

currentVersion=$(jq -r '.version' "$infoFile" 2>/dev/null || echo "0.0.0")

# nix system -> { edgedl path platform, archive extension }
declare -A dlPlatform=(
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

echo "Fetching Antigravity IDE releases..."
releases=$(curl -fsSL "$RELEASES_URL")

if [[ -n "$PIN_VERSION" ]]; then
  latestVersion="$PIN_VERSION"
  executionId=$(echo "$releases" | jq -r --arg v "$PIN_VERSION" '.[] | select(.version == $v) | .execution_id' | head -1 | tr -d '/')
  if [[ -z "$executionId" ]]; then
    echo "Error: version $PIN_VERSION not found in releases list" >&2
    exit 1
  fi
else
  latestVersion=$(echo "$releases" | jq -r '.[0].version')
  executionId=$(echo "$releases" | jq -r '.[0].execution_id' | tr -d '/')
fi

if [[ -z "$latestVersion" || "$latestVersion" == "null" || -z "$executionId" || "$executionId" == "null" ]]; then
  echo "Error: Could not determine latest version from $RELEASES_URL" >&2
  exit 1
fi

echo "  Latest: $latestVersion (build $executionId), current: $currentVersion"

if [[ "$latestVersion" == "$currentVersion" && -z "$PIN_VERSION" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

if [[ "$CHECK_ONLY" == "true" ]]; then
  echo "Update available: $currentVersion -> $latestVersion"
  exit 0
fi

declare -A updates=()
vscodeVersion=""
for platform in "${!dlPlatform[@]}"; do
  p="${dlPlatform[$platform]}"
  ext="${archiveExt[$platform]}"
  url="${EDGEDL_BASE}/${latestVersion}-${executionId}/${p}/Antigravity%20IDE.${ext}"

  echo "  Prefetching $platform..."
  prefetch=$(nix-prefetch-url "$url" --name "AntigravityIDE-${p}.${ext}" --print-path 2>/dev/null)
  sha256_base32=$(echo "$prefetch" | head -n1)
  storePath=$(echo "$prefetch" | tail -n1)
  sha256_hex=$(nix-hash --type sha256 --to-base16 "$sha256_base32")
  updates[$platform]="{\"url\":\"$url\",\"sha256\":\"$sha256_hex\"}"

  # Read the VS Code base version from the linux archive's product.json.
  if [[ "$platform" == "x86_64-linux" ]]; then
    vscodeVersion=$(tar -Oxzf "$storePath" "Antigravity IDE/resources/app/product.json" 2>/dev/null \
      | jq -r '.vsCodeVersion // .version // empty')
  fi
done

if [[ -z "$vscodeVersion" ]]; then
  echo "Warning: could not read VS Code version from archive; preserving existing value" >&2
  vscodeVersion=$(jq -r '.vscodeVersion' "$infoFile" 2>/dev/null || echo "")
fi

echo "Updating $infoFile to version $latestVersion (VS Code $vscodeVersion)..."
jq -n \
  --arg ver "$latestVersion" \
  --arg vver "$vscodeVersion" \
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
