#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch
set -eu -o pipefail

# Get the directory where this script is located
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sourcesFile="$scriptDir/sources.json"

# Extract current version from sources.json
if [[ ! -f "$sourcesFile" ]]; then
  echo "Error: sources.json not found at $sourcesFile" >&2
  exit 1
fi

currentVersion=$(jq -r '.version' "$sourcesFile")
currentVscodeVersion=$(jq -r '.vscodeVersion' "$sourcesFile")

if [[ -z "$currentVersion" ]] || [[ "$currentVersion" == "null" ]]; then
  echo "Error: Could not find version in $sourcesFile" >&2
  exit 1
fi

echo "Current version: $currentVersion"
echo "Current vscodeVersion: $currentVscodeVersion"

declare -A platforms=(
  [x86_64-linux]='linux-x64'
  [aarch64-linux]='linux-arm64'
  [x86_64-darwin]='darwin-x64'
  [aarch64-darwin]='darwin-arm64'
)

declare -A urls=()
declare -A hashes=()
new_version=""

# Fetch version info from Cursor API
echo "Fetching latest version info from Cursor API..."
for platform in "${!platforms[@]}"; do
  api_platform="${platforms[$platform]}"
  echo "Checking $platform ($api_platform)..."

  result=$(curl -s "https://api2.cursor.sh/updates/api/download/stable/$api_platform/cursor")

  if [[ -z "$result" ]]; then
    echo "Error: Failed to fetch version info for $platform" >&2
    exit 1
  fi

  version=$(echo "$result" | jq -r '.version')
  url=$(echo "$result" | jq -r '.downloadUrl')

  if [[ -z "$version" ]] || [[ -z "$url" ]] || [[ "$version" == "null" ]] || [[ "$url" == "null" ]]; then
    echo "Error: Invalid response for $platform" >&2
    exit 1
  fi

  # Check if URL is downloadable
  if ! curl --output /dev/null --silent --head --fail "$url"; then
    echo "Error: URL not reachable for $platform: $url" >&2
    exit 1
  fi

  if [[ -z "$new_version" ]]; then
    new_version="$version"
  elif [[ "$version" != "$new_version" ]]; then
    echo "Error: Version mismatch: $new_version vs $version ($platform)" >&2
    exit 1
  fi

  urls[$platform]="$url"
done

if [[ "$new_version" == "$currentVersion" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

echo "New version: $new_version"
echo "Prefetching hashes..."

# Prefetch and compute hashes
for platform in "${!platforms[@]}"; do
  url="${urls[$platform]}"
  echo "  Prefetching $platform..."
  source=$(nix-prefetch-url "$url" --name "cursor-$new_version-$platform" 2>&1 | tail -1)
  hash=$(nix-hash --to-sri --type sha256 "$source")
  hashes[$platform]="$hash"
done

echo "Updating $sourcesFile..."

# Create backup
cp "$sourcesFile" "${sourcesFile}.bak"

# Build the updated JSON using jq
# Start with the base structure
updated_json=$(jq --arg version "$new_version" --arg vscodeVersion "$currentVscodeVersion" \
  '.version = $version | .vscodeVersion = $vscodeVersion' "$sourcesFile")

# Update each platform's URL and hash
for platform in "${!platforms[@]}"; do
  url="${urls[$platform]}"
  hash="${hashes[$platform]}"

  updated_json=$(echo "$updated_json" | jq --arg platform "$platform" \
    --arg url "$url" --arg hash "$hash" \
    '.sources[$platform].url = $url | .sources[$platform].hash = $hash')
done

# Write the updated JSON back to the file with proper formatting
echo "$updated_json" | jq . > "$sourcesFile"

echo "✅ Updated to version $new_version"
echo ""
echo "Changes:"
echo "  Version: $currentVersion -> $new_version"
echo ""
echo "Please review the changes:"
echo "  git diff $sourcesFile"
echo ""
echo "Backup saved to: ${sourcesFile}.bak"
