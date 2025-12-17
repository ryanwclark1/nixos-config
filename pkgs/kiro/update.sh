#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch nix
set -eu -o pipefail

# Get the directory where this script is located
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
packageFile="$scriptDir/default.nix"
sourcesFile="$scriptDir/sources.json"

# Extract current version from package.nix
currentVersion=$(grep -E '^\s*version\s*=' "$packageFile" | sed -E 's/.*version\s*=\s*"([^"]+)".*/\1/' | head -1)

if [[ -z "$currentVersion" ]]; then
  echo "Error: Could not find version in $packageFile" >&2
  exit 1
fi

echo "Current version: $currentVersion"

# Platform configuration
declare -A platformUrls=(
  [x86_64-linux]="https://prod.download.desktop.kiro.dev/stable/metadata-linux-x64-stable.json"
  [x86_64-darwin]="https://prod.download.desktop.kiro.dev/stable/metadata-dmg-darwin-x64-stable.json"
  [aarch64-darwin]="https://prod.download.desktop.kiro.dev/stable/metadata-dmg-darwin-arm64-stable.json"
)

declare -A platformVersions=()
declare -A platformFileUrls=()
declare -A platformHashes=()

# Fetch metadata for all platforms
echo "Fetching platform information..."
for platform in "${!platformUrls[@]}"; do
  url="${platformUrls[$platform]}"
  echo "  Fetching metadata for $platform..."

  response=$(curl -s "$url")

  if [[ -z "$response" ]]; then
    echo "Error: Failed to fetch metadata for $platform" >&2
    exit 1
  fi

  # Extract file URL and version from metadata
  fileUrl=$(echo "$response" | jq -r '.releases[].updateTo | select(.url | test("\\.(tar|dmg)(\\.|$)")) | .url' | head -1)
  version=$(echo "$response" | jq -r '.currentRelease')

  if [[ -z "$fileUrl" ]] || [[ "$fileUrl" == "null" ]] || [[ -z "$version" ]] || [[ "$version" == "null" ]]; then
    echo "Error: Invalid response for $platform" >&2
    exit 1
  fi

  platformVersions[$platform]="$version"
  platformFileUrls[$platform]="$fileUrl"
done

# Determine the maximum version
maxVersion=""
for platform in "${!platformVersions[@]}"; do
  version="${platformVersions[$platform]}"
  if [[ -z "$maxVersion" ]] || [[ "$version" > "$maxVersion" ]]; then
    maxVersion="$version"
  fi
done

echo "Latest version: $maxVersion"

if [[ "$maxVersion" == "$currentVersion" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

echo "Updating to version $maxVersion..."

# Calculate hashes
echo "Calculating hashes..."
for platform in "${!platformFileUrls[@]}"; do
  fileUrl="${platformFileUrls[$platform]}"
  echo "  Prefetching $platform..."

  sourcePath=$(nix-prefetch-url "$fileUrl" --name "kiro-${maxVersion}-${platform}" 2>&1 | tail -1)
  hash=$(nix-hash --to-sri --type sha256 "$sourcePath")

  platformHashes[$platform]="$hash"
done

# Extract vscode version from the Linux tar.gz archive
echo "Extracting VSCode version..."
linuxArchivePath=$(nix-prefetch-url --print-path "${platformFileUrls[x86_64-linux]}" 2>&1 | tail -1)
vscodeVersion=$(tar -Oxzf "$linuxArchivePath" "Kiro/resources/app/product.json" 2>/dev/null | jq -r '.vsCodeVersion' || echo "")

if [[ -z "$vscodeVersion" ]] || [[ "$vscodeVersion" == "null" ]]; then
  echo "⚠️  Warning: Could not extract vsCodeVersion from product.json"
  echo "   You may need to update it manually"
  vscodeVersion=$(grep -E '^\s*vscodeVersion\s*=' "$packageFile" | sed -E 's/.*vscodeVersion\s*=\s*"([^"]+)".*/\1/' | head -1)
fi

echo "VSCode version: $vscodeVersion"

# Create backups
cp "$packageFile" "${packageFile}.bak"
cp "$sourcesFile" "${sourcesFile}.bak"

# Update package.nix
sed -i "s/version = \"$currentVersion\"/version = \"$maxVersion\"/" "$packageFile"
if [[ -n "$vscodeVersion" ]]; then
  currentVSCodeVersion=$(grep -E '^\s*vscodeVersion\s*=' "$packageFile" | sed -E 's/.*vscodeVersion\s*=\s*"([^"]+)".*/\1/' | head -1)
  if [[ -n "$currentVSCodeVersion" ]]; then
    sed -i "s/vscodeVersion = \"$currentVSCodeVersion\"/vscodeVersion = \"$vscodeVersion\"/" "$packageFile"
  fi
fi

# Generate sources.json
echo "Generating sources.json..."
jsonContent="{}"
for platform in "${!platformFileUrls[@]}"; do
  url="${platformFileUrls[$platform]}"
  hash="${platformHashes[$platform]}"
  jsonContent=$(echo "$jsonContent" | jq --arg platform "$platform" \
    --arg url "$url" \
    --arg hash "$hash" \
    '. + {($platform): {url: $url, hash: $hash}}')
done
echo "$jsonContent" > "$sourcesFile"

echo "✅ Updated to version $maxVersion"
echo ""
echo "Changes:"
echo "  Version: $currentVersion -> $maxVersion"
if [[ -n "$vscodeVersion" ]]; then
  echo "  VSCode version: $vscodeVersion"
fi
echo ""
echo "Please review the changes:"
echo "  git diff $packageFile"
echo "  git diff $sourcesFile"
echo ""
echo "Backups saved to: ${packageFile}.bak and ${sourcesFile}.bak"
