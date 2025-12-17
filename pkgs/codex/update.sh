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

# Fetch latest stable release from GitHub API (skip pre-releases)
echo "Fetching latest release from GitHub..."
latestRelease=$(curl -s "https://api.github.com/repos/openai/codex/releases" | jq -r '[.[] | select(.prerelease == false)][0].tag_name' | sed 's/^rust-v//')

if [[ -z "$latestRelease" ]] || [[ "$latestRelease" == "null" ]]; then
  echo "Error: Failed to fetch latest release" >&2
  exit 1
fi

# Remove 'rust-v' prefix if present
latestVersion="${latestRelease#rust-v}"

echo "Latest version: $latestVersion"

if [[ "$latestVersion" == "$currentVersion" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

echo "Updating to version $latestVersion..."

# Prefetch GitHub source
echo "Prefetching GitHub source..."
GITHUB_TARBALL_URL="https://github.com/openai/codex/archive/refs/tags/rust-v${latestVersion}.tar.gz"
echo "  URL: $GITHUB_TARBALL_URL"

SOURCE_PATH=$(nix-prefetch-url "$GITHUB_TARBALL_URL" --name "codex-rust-v${latestVersion}.tar.gz" 2>&1 | tail -1)
SOURCE_HASH=$(nix-hash --to-sri --type sha256 "$SOURCE_PATH")

if [[ -z "$SOURCE_HASH" ]]; then
  echo "Error: Failed to get source hash" >&2
  exit 1
fi

echo "Source hash: $SOURCE_HASH"

# Create backup
cp "$packageFile" "${packageFile}.bak"

# Update version
sed -i "s/version = \"$currentVersion\"/version = \"$latestVersion\"/" "$packageFile"

# Update source hash
sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$SOURCE_HASH\"|" "$packageFile"

# Update rev
sed -i "s|rev = \"rust-v\${finalAttrs.version}\"|rev = \"rust-v${latestVersion}\"|" "$packageFile"

# Update changelog URL
sed -i "s|rust-v\${finalAttrs.version}|rust-v${latestVersion}|g" "$packageFile"

echo "✅ Updated to version $latestVersion"
echo ""
echo "Changes:"
echo "  Version: $currentVersion -> $latestVersion"
echo "  Source hash: $SOURCE_HASH"
echo ""
echo "⚠️  IMPORTANT: You need to compute cargoHash by building:"
echo "   nix build .#codex"
echo "   The build will show the correct cargoHash - update it in the package file."
echo ""
echo "Please review the changes:"
echo "  git diff $packageFile"
echo ""
echo "Backup saved to: ${packageFile}.bak"


