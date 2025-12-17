#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch
set -eu -o pipefail

# Get the directory where this script is located
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
packageFile="$scriptDir/default.nix"

# Extract current version from package.nix
currentVersion=$(grep -E '^\s*version\s*=' "$packageFile" | sed -E 's/.*version\s*=\s*"([^"]+)".*/\1/' | head -1)

if [[ -z "$currentVersion" ]]; then
  echo "Error: Could not find version in $packageFile" >&2
  exit 1
fi

echo "Current version: $currentVersion"

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

echo "Updating $packageFile..."

# Create backup
cp "$packageFile" "${packageFile}.bak"

# Update version
sed -i "s/version = \"$currentVersion\"/version = \"$new_version\"/" "$packageFile"

# Update URLs and hashes for each platform
for platform in "${!platforms[@]}"; do
  url="${urls[$platform]}"
  hash="${hashes[$platform]}"

  # Escape special characters in URL for sed
  escaped_url=$(echo "$url" | sed 's/[[\.*^$()+?{|]/\\&/g')

  # Update URL (match the line after the platform declaration)
  sed -i "/^\s*$platform\s*=\s*fetchurl\s*{/,/^\s*};/ {
    s|url = \"[^\"]*\"|url = \"$url\"|
    s|hash = \"[^\"]*\"|hash = \"$hash\"|
  }" "$packageFile"
done

echo "✅ Updated to version $new_version"
echo ""
echo "Changes:"
echo "  Version: $currentVersion -> $new_version"
echo ""
echo "Please review the changes:"
echo "  git diff $packageFile"
echo ""
echo "Backup saved to: ${packageFile}.bak"
