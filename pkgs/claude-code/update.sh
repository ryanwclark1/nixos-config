#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch nix
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

# Fetch latest version from npm registry
echo "Fetching latest version from npm registry..."
latestVersion=$(curl -s "https://registry.npmjs.org/@anthropic-ai/claude-code" | jq -r '.["dist-tags"].latest')

if [[ -z "$latestVersion" ]] || [[ "$latestVersion" == "null" ]]; then
  echo "Error: Failed to fetch latest version" >&2
  exit 1
fi

echo "Latest version: $latestVersion"

if [[ "$latestVersion" == "$currentVersion" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

echo "Updating to version $latestVersion..."

# Prefetch npm tarball
echo "Prefetching npm tarball..."
NPM_URL="https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${latestVersion}.tgz"
echo "  URL: $NPM_URL"

SOURCE_PATH=$(nix-prefetch-url "$NPM_URL" --name "claude-code-${latestVersion}.tgz" 2>&1 | tail -1)
SOURCE_HASH=$(nix-hash --to-sri --type sha256 "$SOURCE_PATH")

if [[ -z "$SOURCE_HASH" ]]; then
  echo "Error: Failed to get source hash" >&2
  exit 1
fi

echo "Source hash: $SOURCE_HASH"

# Download and update package-lock.json
echo "Downloading package-lock.json..."
# Extract package-lock.json from the tarball
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

curl -s "$NPM_URL" | tar -xz -C "$TEMP_DIR" package/package-lock.json 2>/dev/null || true

if [[ -f "$TEMP_DIR/package/package-lock.json" ]]; then
  cp "$TEMP_DIR/package/package-lock.json" "$scriptDir/package-lock.json"
  echo "✅ Updated package-lock.json"
else
  echo "⚠️  Warning: Could not extract package-lock.json from tarball"
  echo "   You may need to update it manually or generate it"
fi

# Create backup
cp "$packageFile" "${packageFile}.bak"

# Update version
sed -i "s/version = \"$currentVersion\"/version = \"$latestVersion\"/" "$packageFile"

# Update source hash
sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$SOURCE_HASH\"|" "$packageFile"

# Update URL (it uses version variable, so this should be automatic, but let's be explicit)
sed -i "s|claude-code-\${finalAttrs.version}|claude-code-${latestVersion}|" "$packageFile"

echo "✅ Updated to version $latestVersion"
echo ""
echo "Changes:"
echo "  Version: $currentVersion -> $latestVersion"
echo "  Source hash: $SOURCE_HASH"
echo ""
echo "⚠️  IMPORTANT: You need to compute npmDepsHash by building:"
echo "   nix build .#claude-code"
echo "   The build will show the correct npmDepsHash - update it in the package file."
echo ""
echo "Please review the changes:"
echo "  git diff $packageFile"
echo "  git diff $scriptDir/package-lock.json"
echo ""
echo "Backup saved to: ${packageFile}.bak"


