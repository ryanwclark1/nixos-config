#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch
set -eu -o pipefail

# Get the directory where this script is located
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
packageFile="$scriptDir/default.nix"

# Extract current release from package.nix (format: YYYY.MM.DD-{hash})
currentRelease=$(grep -E 'url.*lab/' "$packageFile" | sed -n 's|.*lab/\([^/]*\)/.*|\1|p' | head -1)
currentVersion=$(grep -E '^\s*version\s*=' "$packageFile" | sed -E 's/.*version\s*=\s*"([^"]+)".*/\1/' | head -1)

if [[ -z "$currentRelease" ]] || [[ -z "$currentVersion" ]]; then
  echo "Error: Could not find release or version in $packageFile" >&2
  exit 1
fi

echo "Current release: $currentRelease"
echo "Current version: $currentVersion"

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

  urls[$platform]="$url"
  hashes[$platform]="$hash"
done

echo "Updating $packageFile..."

# Create backup
cp "$packageFile" "${packageFile}.bak"

# Update version
sed -i "s/version = \"$currentVersion\"/version = \"$latestVersion\"/" "$packageFile"

# Update URLs and hashes for each platform
for platform in "${!platforms[@]}"; do
  url="${urls[$platform]}"
  hash="${hashes[$platform]}"

  # Update URL (match the line in the sources block)
  sed -i "/^\s*$platform\s*=\s*fetchurl\s*{/,/^\s*};/ {
    s|url = \"[^\"]*\"|url = \"$url\"|
    s|hash = \"[^\"]*\"|hash = \"$hash\"|
  }" "$packageFile"
done

echo "✅ Updated to release $latestRelease (version $latestVersion)"
echo ""
echo "Changes:"
echo "  Release: $currentRelease -> $latestRelease"
echo "  Version: $currentVersion -> $latestVersion"
echo ""
echo "Please review the changes:"
echo "  git diff $packageFile"
echo ""
echo "Backup saved to: ${packageFile}.bak"


