#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch
set -eu -o pipefail

# Get the directory where this script is located
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sourcesFile="$scriptDir/sources.json"

# Extract current version and release from sources.json
if [[ ! -f "$sourcesFile" ]]; then
  echo "Error: sources.json not found at $sourcesFile" >&2
  exit 1
fi

currentVersion=$(jq -r '.version' "$sourcesFile")
currentRelease=$(jq -r '.release' "$sourcesFile")

if [[ -z "$currentVersion" ]] || [[ "$currentVersion" == "null" ]]; then
  echo "Error: Could not find version in $sourcesFile" >&2
  exit 1
fi

if [[ -z "$currentRelease" ]] || [[ "$currentRelease" == "null" ]]; then
  echo "Error: Could not find release in $sourcesFile" >&2
  exit 1
fi

echo "Current version: $currentVersion"
echo "Current release: $currentRelease"

# Fetch latest release from cursor.com/install page
echo "Fetching latest release from cursor.com/install..."
latestRelease=$(curl -s "https://cursor.com/install" | grep -oP "lab/\K[^/]+" | head -1)

if [[ -z "$latestRelease" ]]; then
  echo "Error: Failed to fetch latest release" >&2
  exit 1
fi

# Check if release matches the pattern YYYY.MM.DD-{commithash}
if [[ "$latestRelease" =~ ^[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[a-f0-9]+$ ]]; then
  timestamp=$(echo "$latestRelease" | cut -d"-" -f1 | tr "." "-")
  latestVersion="0-unstable-$timestamp"
else
  latestVersion="$latestRelease"
fi

echo "Latest release: $latestRelease"
echo "Latest version: $latestVersion"

if [[ "$latestRelease" == "$currentRelease" ]]; then
  echo "Already up to date: $currentRelease"
  exit 0
fi

echo "Updating to $latestRelease ($latestVersion)..."

declare -A platforms=(
  [x86_64-linux]="linux/x64"
  [aarch64-linux]="linux/arm64"
  [x86_64-darwin]="darwin/x64"
  [aarch64-darwin]="darwin/arm64"
)

declare -A urls=()
declare -A hashes=()

# Prefetch and compute hashes
for platform in "${!platforms[@]}"; do
  path="${platforms[$platform]}"
  url="https://downloads.cursor.com/lab/$latestRelease/$path/agent-cli-package.tar.gz"

  echo "  Checking $platform..."
  if ! curl --output /dev/null --silent --head --fail "$url"; then
    echo "Error: URL not reachable for $platform: $url" >&2
    exit 1
  fi

  echo "  Prefetching $platform..."
  source=$(nix-prefetch-url "$url" --name "cursor-cli-$latestVersion-$platform" 2>&1 | tail -1)
  hash=$(nix-hash --to-sri --type sha256 "$source")
  hashes[$platform]="$hash"
  urls[$platform]="$url"
done

echo "Updating $sourcesFile..."

# Create backup
cp "$sourcesFile" "${sourcesFile}.bak"

# Build the updated JSON using jq
# Start with the base structure
updated_json=$(jq --arg version "$latestVersion" --arg release "$latestRelease" \
  '.version = $version | .release = $release' "$sourcesFile")

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

echo "✅ Updated to release $latestRelease (version $latestVersion)"
echo ""
echo "Changes:"
echo "  Release: $currentRelease -> $latestRelease"
echo "  Version: $currentVersion -> $latestVersion"
echo ""
echo "Please review the changes:"
echo "  git diff $sourcesFile"
echo ""
echo "Backup saved to: ${sourcesFile}.bak"
