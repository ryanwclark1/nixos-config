#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq
set -eu -o pipefail

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
infoFile="$scriptDir/information.json"

currentVersion=$(jq -r '.version' "$infoFile" 2>/dev/null || echo "0.0.0")

# API endpoint for Antigravity CLI manifests
MANIFEST_BASE="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests"

declare -A platforms=(
  [x86_64-linux]="linux_amd64"
  [aarch64-linux]="linux_arm64"
  [x86_64-darwin]="darwin_amd64"
  [aarch64-darwin]="darwin_arm64"
)

declare -A updates=()
latestVersion=""

echo "Fetching latest version information for Antigravity CLI..."
for platform in "${!platforms[@]}"; do
  manifest_platform="${platforms[$platform]}"
  echo "  Checking $platform..."

  response=$(curl -s "${MANIFEST_BASE}/${manifest_platform}.json")
  
  url=$(echo "$response" | jq -r '.url')
  sha512=$(echo "$response" | jq -r '.sha512')
  version=$(echo "$response" | jq -r '.version')

  if [[ -z "$version" ]] || [[ "$version" == "null" ]]; then
    echo "Error: Could not find version for $platform" >&2
    exit 1
  fi

  if [[ -z "$latestVersion" ]]; then
    latestVersion="$version"
  elif [[ "$version" != "$latestVersion" ]]; then
    echo "Error: Version mismatch across platforms: $latestVersion vs $version" >&2
    exit 1
  fi

  updates[$platform]="{\"url\":\"$url\",\"sha512\":\"$sha512\"}"
done

if [[ "$latestVersion" == "$currentVersion" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

echo "Updating $infoFile to version $latestVersion..."
jq -n \
  --arg ver "$latestVersion" \
  --arg x64l "${updates[x86_64-linux]}" \
  --arg arml "${updates[aarch64-linux]}" \
  --arg x64d "${updates[x86_64-darwin]}" \
  --arg armd "${updates[aarch64-darwin]}" \
  '{
    version: $ver,
    sources: {
      "x86_64-linux": ($x64l | fromjson),
      "aarch64-linux": ($arml | fromjson),
      "x86_64-darwin": ($x64d | fromjson),
      "aarch64-darwin": ($armd | fromjson)
    }
  }' > "$infoFile"

echo "✅ Updated to $latestVersion"
