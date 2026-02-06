#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch-git nix
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

# Prefetch GitHub source using nix-prefetch-git (matches fetchFromGitHub)
echo "Prefetching GitHub source..."
GITHUB_REPO="https://github.com/openai/codex"
GITHUB_TAG="rust-v${latestVersion}"
echo "  Repository: $GITHUB_REPO"
echo "  Tag: $GITHUB_TAG"

# Use nix-prefetch-git to get the hash in the correct format for fetchFromGitHub
# nix-prefetch-git outputs JSON at the end - extract the JSON block and parse it
PREFETCH_OUTPUT=$(nix-prefetch-git --url "$GITHUB_REPO" --rev "$GITHUB_TAG" 2>&1)
# Extract JSON object (starts with { and ends with })
JSON_BLOCK=$(echo "$PREFETCH_OUTPUT" | grep -o '{.*}' | tail -1)
SOURCE_HASH=$(echo "$JSON_BLOCK" | jq -r '.hash // empty' 2>/dev/null)

if [[ -z "$SOURCE_HASH" ]] || [[ "$SOURCE_HASH" == "null" ]]; then
  echo "Warning: Could not extract hash from JSON, trying alternative method..." >&2
  # Fallback: look for hash in the output directly
  SOURCE_HASH=$(echo "$PREFETCH_OUTPUT" | grep -oE 'sha256-[A-Za-z0-9+/=]{43}' | head -1)
fi

if [[ -z "$SOURCE_HASH" ]] || [[ "$SOURCE_HASH" == "null" ]]; then
  echo "Error: Failed to get source hash from nix-prefetch-git" >&2
  echo "Output was:" >&2
  echo "$PREFETCH_OUTPUT" >&2
  exit 1
fi

echo "Source hash: $SOURCE_HASH"

# Create backup
cp "$packageFile" "${packageFile}.bak"

# Update version
sed -i "s/version = \"$currentVersion\"/version = \"$latestVersion\"/" "$packageFile"

# Update source hash (matches fetchFromGitHub hash field)
sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$SOURCE_HASH\"|" "$packageFile"

# Note: tag field uses ${finalAttrs.version} so it updates automatically with version
# No need to update it manually

# Update changelog URL
sed -i "s|rust-v\${finalAttrs.version}|rust-v${latestVersion}|g" "$packageFile"

# Reset cargoHash to empty string so user can easily update it
# This makes it clear that cargoHash needs to be recomputed
if grep -q 'cargoHash = "sha256-' "$packageFile"; then
  sed -i 's|cargoHash = "sha256-[^"]*"|cargoHash = ""|' "$packageFile"
  echo "⚠️  Reset cargoHash to empty string - needs to be recomputed"
fi

echo "✅ Updated to version $latestVersion"
echo ""
echo "Changes:"
echo "  Version: $currentVersion -> $latestVersion"
echo "  Source hash: $SOURCE_HASH"
echo ""
echo "⚠️  IMPORTANT: You need to compute cargoHash by building:"
echo "   1. Set cargoHash = \"\" in the package file (already done)"
echo "   2. Build: nix build .#codex"
echo "   3. Copy the 'got: sha256-...' value from the error message"
echo "   4. Update cargoHash in the package file with the new hash"
echo ""
echo "Please review the changes:"
echo "  git diff $packageFile"
echo ""
echo "Backup saved to: ${packageFile}.bak"


