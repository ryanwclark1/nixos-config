#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch-github nix
set -eu -o pipefail

# Get the directory where this script is located
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
packageFile="$scriptDir/default.nix"
helperScript="$scriptDir/../../scripts/lib/package-update-helpers.sh"

if [[ ! -f "$helperScript" ]]; then
  echo "Error: helper script not found at $helperScript" >&2
  exit 1
fi

# shellcheck source=../../scripts/lib/package-update-helpers.sh
source "$helperScript"

repoRoot="$(cd "$scriptDir/../.." && pwd)"
SYSTEM="${NIX_SYSTEM:-$(get_nix_system)}"
beforeUpdatePath=""

# Extract current version from package.nix
currentVersion=$(grep -E '^\s*version\s*=' "$packageFile" | sed -E 's/.*version\s*=\s*"([^"]+)".*/\1/' | head -1)

if [[ -z "$currentVersion" ]]; then
  echo "Error: Could not find version in $packageFile" >&2
  exit 1
fi

echo "Current version: $currentVersion"

if [[ "${PACKAGE_UPDATE_ORCHESTRATED:-}" != "true" ]]; then
  echo "Diffing local derivation against nixpkgs-unstable..."
  report_upstream_derivation_diff "gemini-cli" "$packageFile" || true
  echo ""

  beforeUpdatePath=$(build_local_package_output_path "$repoRoot" "gemini-cli" "$SYSTEM" 2>/dev/null || true)
  if [[ -n "$beforeUpdatePath" ]]; then
    echo "Current closure:"
    nix path-info -Shr "$beforeUpdatePath"
    echo ""
  else
    echo "Warning: could not build current gemini-cli before update; skipping before/after closure diff" >&2
  fi
fi

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

# Prefetch GitHub source using nix-prefetch-github (matches fetchFromGitHub behavior)
echo "Prefetching GitHub source..."
echo "  Owner: google-gemini"
echo "  Repo: gemini-cli"
echo "  Tag: v${latestVersion}"

# Use nix-prefetch-github with JSON output for reliable parsing
# This matches fetchFromGitHub's hash calculation exactly
PREFETCH_JSON=$(nix-prefetch-github google-gemini gemini-cli --tag "v${latestVersion}" --json 2>/dev/null)
PREFETCH_EXIT=$?

if [[ $PREFETCH_EXIT -ne 0 ]]; then
  echo "Error: Failed to prefetch GitHub source (exit code: $PREFETCH_EXIT)" >&2
  # Try again without suppressing stderr to show the actual error
  nix-prefetch-github google-gemini gemini-cli --tag "v${latestVersion}" --json >&2
  exit 1
fi

# Extract hash from JSON output
SOURCE_HASH=$(echo "$PREFETCH_JSON" | jq -r '.hash' 2>/dev/null)

if [[ -z "$SOURCE_HASH" ]] || [[ "$SOURCE_HASH" == "null" ]]; then
  echo "Error: Failed to extract hash from nix-prefetch-github JSON output" >&2
  echo "Output was:" >&2
  echo "$PREFETCH_JSON" >&2
  exit 1
fi

echo "Source hash: $SOURCE_HASH"

# Create backup
cp "$packageFile" "${packageFile}.bak"

# Update version
sed -i "s/version = \"$currentVersion\"/version = \"$latestVersion\"/" "$packageFile"

# Update source hash
sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$SOURCE_HASH\"|" "$packageFile"

# Update tag/rev in fetchFromGitHub
# Check if using tag format (preferred) or rev format
if grep -q "tag = \"v\${finalAttrs.version}\"" "$packageFile"; then
  # Using tag format - no need to update, it uses the version variable
  echo "  Using tag format (auto-updates with version)"
elif grep -q "tag = \"v" "$packageFile"; then
  # Using hardcoded tag - update it
  sed -i "s|tag = \"v[^\"]*\"|tag = \"v${latestVersion}\"|" "$packageFile"
elif grep -q "rev = \"v" "$packageFile"; then
  # Using rev format - update it
  sed -i "s|rev = \"v[^\"]*\"|rev = \"v${latestVersion}\"|" "$packageFile"
fi

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

if [[ "${PACKAGE_UPDATE_ORCHESTRATED:-}" != "true" ]]; then
  echo ""
  echo "Validating updated package build..."
  postUpdatePath=$(build_local_package_output_path "$repoRoot" "gemini-cli" "$SYSTEM")
  echo "Updated closure:"
  nix path-info -Shr "$postUpdatePath"

  if [[ -n "$beforeUpdatePath" ]]; then
    echo ""
    echo "Closure diff:"
    nix store diff-closures "$beforeUpdatePath" "$postUpdatePath" || true
  fi
fi
