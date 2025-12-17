#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch
set -eu -o pipefail

# Get the directory where this script is located
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
infoFile="$scriptDir/information.json"

# Extract current version from information.json
currentVersion=$(jq -r '.version' "$infoFile" 2>/dev/null || echo "")

if [[ -z "$currentVersion" ]]; then
  echo "Error: Could not find version in $infoFile" >&2
  exit 1
fi

echo "Current version: $currentVersion"

# API endpoint
API_BASE="https://antigravity-auto-updater-974169037036.us-central1.run.app/api/update"

declare -A platforms=(
  [x86_64-linux]="linux-x64"
  [aarch64-linux]="linux-arm64"
  [x86_64-darwin]="darwin"
  [aarch64-darwin]="darwin-arm64"
)

declare -A updates=()
latestVersion=""
latestVSCodeVersion=""

# Fetch latest information from API for all platforms
echo "Fetching latest version information from Antigravity API..."
for platform in "${!platforms[@]}"; do
  api_platform="${platforms[$platform]}"
  echo "  Checking $platform ($api_platform)..."

  response=$(curl -s "${API_BASE}/${api_platform}/stable/latest")

  if [[ -z "$response" ]]; then
    echo "Error: Failed to fetch version info for $platform" >&2
    exit 1
  fi

  url=$(echo "$response" | jq -r '.url')
  sha256=$(echo "$response" | jq -r '.sha256hash')
  vscodeVersion=$(echo "$response" | jq -r '.productVersion')

  # Extract version from URL
  version=$(echo "$url" | grep -oP 'antigravity/stable/\K[\d.]+' | head -1)

  if [[ -z "$version" ]] || [[ -z "$url" ]] || [[ -z "$sha256" ]]; then
    echo "Error: Invalid response for $platform" >&2
    exit 1
  fi

  if [[ -z "$latestVersion" ]]; then
    latestVersion="$version"
    latestVSCodeVersion="$vscodeVersion"
  elif [[ "$version" != "$latestVersion" ]]; then
    echo "Error: Version mismatch: $latestVersion vs $version ($platform)" >&2
    exit 1
  elif [[ "$vscodeVersion" != "$latestVSCodeVersion" ]]; then
    echo "Error: VSCode version mismatch: $latestVSCodeVersion vs $vscodeVersion ($platform)" >&2
    exit 1
  fi

  updates[$platform]="{\"url\":\"$url\",\"sha256\":\"$sha256\"}"
done

if [[ "$latestVersion" == "$currentVersion" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

echo "Latest version: $latestVersion"
echo "Latest VSCode version: $latestVSCodeVersion"
echo "Updating information.json..."

# Create backup
cp "$infoFile" "${infoFile}.bak"

# Build new information.json
{
  echo "{"
  echo "  \"version\": \"$latestVersion\","
  echo "  \"vscodeVersion\": \"$latestVSCodeVersion\","
  echo "  \"sources\": {"

  first=true
  for platform in "${!platforms[@]}"; do
    if [[ "$first" == "true" ]]; then
      first=false
    else
      echo ","
    fi
    echo -n "    \"$platform\": ${updates[$platform]}"
  done

  echo ""
  echo "  }"
  echo "}"
} > "$infoFile"

echo "✅ Updated to version $latestVersion (VSCode $latestVSCodeVersion)"
echo ""
echo "Changes:"
echo "  Version: $currentVersion -> $latestVersion"
echo "  VSCode version: $(jq -r '.vscodeVersion' "${infoFile}.bak") -> $latestVSCodeVersion"
echo ""
echo "Please review the changes:"
echo "  git diff $infoFile"
echo ""
echo "Backup saved to: ${infoFile}.bak"


