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

# Create backup
cp "$packageFile" "${packageFile}.bak"

# Update version
sed -i "s/version = \"$currentVersion\"/version = \"$latestVersion\"/" "$packageFile"

# Update source hash
sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$SOURCE_HASH\"|" "$packageFile"

# Update rev (fetchFromGitHub uses rev, not tag)
sed -i "s|rev = \"v\${finalAttrs.version}\"|rev = \"v${latestVersion}\"|" "$packageFile"

echo "✅ Updated version and source hash"
echo ""

# Check if user wants to skip npmDepsHash computation
SKIP_NPM_HASH=false
if [[ "${SKIP_NPM_HASH:-}" == "true" ]] || [[ "${1:-}" == "--skip-npm-hash" ]]; then
  SKIP_NPM_HASH=true
  echo "Skipping npmDepsHash computation (--skip-npm-hash flag set)"
  echo ""
  NPM_DEPS_HASH=""
else
  # Now compute npmDepsHash by attempting to build
  echo "Computing npmDepsHash..."
  echo "  This may take a few minutes as we need to fetch npm dependencies..."
  echo "  (Use --skip-npm-hash to skip this step)"
  echo ""

  # Get the repo root (assuming we're in a flake-based setup)
  repoRoot="$(cd "$scriptDir/../.." && pwd)"

  # Detect system architecture
  SYSTEM="${NIX_SYSTEM:-$(nix eval --impure --expr 'builtins.currentSystem' 2>/dev/null || echo "x86_64-linux")}"

  # Try to build the package and capture the hash from error output
  # We'll try multiple build commands to find what works
  BUILD_OUTPUT=""
  NPM_DEPS_HASH=""

  # Try different build commands in order of preference
  for build_cmd in \
    "cd '$repoRoot' && nix build --no-link '.#packages.${SYSTEM}.gemini-cli' 2>&1" \
    "cd '$repoRoot' && nix build --no-link .#gemini-cli 2>&1" \
    "nix build --no-link -f '<nixpkgs>' -A gemini-cli 2>&1" \
    "nix-build --no-out-link -A gemini-cli 2>&1"
  do
    echo "  Trying build command..."
    set +e  # Allow command to fail
    BUILD_OUTPUT=$(eval "$build_cmd" 2>&1)
    BUILD_EXIT=$?
    set -e

    if [[ $BUILD_EXIT -eq 0 ]]; then
      # Build succeeded - hash was already correct or we got lucky
      echo "  ✅ Build succeeded! npmDepsHash appears to be correct."
      break
    else
      # Build failed - check if it's a hash mismatch error
      if echo "$BUILD_OUTPUT" | grep -q "hash mismatch\|got:"; then
        # Extract the hash from the error message
        # Nix error format: "got:    sha256-..." or "specified: sha256-... got: sha256-..."
        # Use sed for portability (works on both GNU and BSD)
        NPM_DEPS_HASH=$(echo "$BUILD_OUTPUT" | sed -n 's/.*got:[[:space:]]*\(sha256-[A-Za-z0-9+/=]*\).*/\1/p' | head -1)

        if [[ -z "$NPM_DEPS_HASH" ]]; then
          # Try alternative format: look for sha256- after "got:"
          NPM_DEPS_HASH=$(echo "$BUILD_OUTPUT" | grep -o "sha256-[A-Za-z0-9+/=]*" | grep -v "specified:" | tail -1 || echo "")
        fi

        if [[ -n "$NPM_DEPS_HASH" ]]; then
          echo "  ✅ Found npmDepsHash in build error: $NPM_DEPS_HASH"
          break
        fi
      fi

      # If we didn't find a hash, continue to next build command
      if [[ -z "$NPM_DEPS_HASH" ]]; then
        continue
      fi
    fi
  done

  if [[ -z "$NPM_DEPS_HASH" ]]; then
    echo ""
    echo "⚠️  Warning: Could not automatically determine npmDepsHash"
    echo "   The build command may need adjustment, or the hash format may have changed."
    echo ""
    echo "   To compute manually:"
    echo "   1. Try building: cd '$repoRoot' && nix build '.#packages.${SYSTEM}.gemini-cli'"
    echo "   2. Look for 'got: sha256-...' in the error message"
    echo "   3. Update npmDepsHash in $packageFile"
    echo ""
    echo "   Build output saved to: ${packageFile}.build-error.log"
    echo "$BUILD_OUTPUT" > "${packageFile}.build-error.log"
  else
    # Update npmDepsHash in the file
    echo "  Updating npmDepsHash in package file..."
    sed -i "s|npmDepsHash = \"sha256-[^\"]*\"|npmDepsHash = \"$NPM_DEPS_HASH\"|" "$packageFile"
    echo "  ✅ Updated npmDepsHash: $NPM_DEPS_HASH"
  fi
fi

echo ""
echo "✅ Updated to version $latestVersion"
echo ""
echo "Changes:"
echo "  Version: $currentVersion -> $latestVersion"
echo "  Source hash: $SOURCE_HASH"
if [[ -n "$NPM_DEPS_HASH" ]]; then
  echo "  npmDepsHash: $NPM_DEPS_HASH"
fi
echo ""
echo "Please review the changes:"
echo "  git diff $packageFile"
echo ""
echo "Backup saved to: ${packageFile}.bak"

