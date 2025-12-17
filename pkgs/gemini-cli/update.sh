#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch-github nix
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

# Fetch latest stable release from GitHub API
echo "Fetching latest release from GitHub..."
latestRelease=$(curl -s "https://api.github.com/repos/google-gemini/gemini-cli/releases/latest" | jq -r '.tag_name' | sed 's/^v//')

if [[ -z "$latestRelease" ]] || [[ "$latestRelease" == "null" ]]; then
  echo "Error: Failed to fetch latest release" >&2
  exit 1
fi

# Remove 'v' prefix if present
latestVersion="${latestRelease#v}"

echo "Latest version: $latestVersion"

if [[ "$latestVersion" == "$currentVersion" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

echo "Updating to version $latestVersion..."

# Prefetch GitHub source (using tarball URL)
echo "Prefetching GitHub source..."
GITHUB_TARBALL_URL="https://github.com/google-gemini/gemini-cli/archive/refs/tags/v${latestVersion}.tar.gz"
echo "  URL: $GITHUB_TARBALL_URL"

SOURCE_PATH=$(nix-prefetch-url "$GITHUB_TARBALL_URL" --name "gemini-cli-${latestVersion}.tar.gz" 2>&1 | tail -1)
SOURCE_HASH=$(nix-hash --to-sri --type sha256 "$SOURCE_PATH")

if [[ -z "$SOURCE_HASH" ]]; then
  echo "Error: Failed to get source hash" >&2
  exit 1
fi

echo "Source hash: $SOURCE_HASH"

# For npmDepsHash, we need to build the package to get it
# This is more complex, so we'll use a placeholder and let the user know
echo ""
echo "⚠️  Note: npmDepsHash needs to be computed by building the package."
echo "   After updating, run: nix build .#gemini-cli"
echo "   The build will fail with the correct hash - update the package file with it."
echo ""

# Create backup
cp "$packageFile" "${packageFile}.bak"

# Update version
sed -i "s/version = \"$currentVersion\"/version = \"$latestVersion\"/" "$packageFile"

# Update source hash
sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$SOURCE_HASH\"|" "$packageFile"

# Update rev (fetchFromGitHub uses rev, not tag)
sed -i "s|rev = \"v\${finalAttrs.version}\"|rev = \"v${latestVersion}\"|" "$packageFile"

echo "✅ Updated to version $latestVersion"
echo ""
echo "Changes:"
echo "  Version: $currentVersion -> $latestVersion"
echo "  Source hash: $SOURCE_HASH"
echo ""
echo "⚠️  IMPORTANT: You need to compute npmDepsHash by building:"
echo "   nix build .#gemini-cli"
echo "   The build will show the correct npmDepsHash - update it in the package file."
echo ""
echo "Please review the changes:"
echo "  git diff $packageFile"
echo ""
echo "Backup saved to: ${packageFile}.bak"

