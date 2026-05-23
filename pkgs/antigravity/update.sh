#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq
set -eu -o pipefail

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
infoFile="$scriptDir/information.json"

currentVersion=$(jq -r '.version' "$infoFile" 2>/dev/null || echo "0.0.0")

# API endpoint for Agent Manager (Hub)
API_BASE="https://antigravity-auto-updater-974169037036.us-central1.run.app/api/update"

declare -A platforms=(
  [x86_64-linux]="linux-x64"
  [aarch64-linux]="linux-arm64"
  [x86_64-darwin]="darwin"
  [aarch64-darwin]="darwin-arm64"
)

declare -A updates=()
latestVersion=""

echo "Fetching latest version information for Antigravity Agent Manager..."
for platform in "${!platforms[@]}"; do
  api_platform="${platforms[$platform]}"
  echo "  Checking $platform..."

  response=$(curl -s "${API_BASE}/${api_platform}/stable/latest")
  
  url=$(echo "$response" | jq -r '.url')
  sha256=$(echo "$response" | jq -r '.sha256hash')
  version=$(echo "$response" | jq -r '.productVersion')

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

  updates[$platform]="{\"url\":\"$url\",\"sha256\":\"$sha256\"}"
done

if [[ "$latestVersion" == "$currentVersion" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

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
