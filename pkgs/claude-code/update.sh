#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix nodejs
set -eu -o pipefail

# Get the directory where this script is located
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
packageFile="$scriptDir/default.nix"
targetAttr="claude-code-npm"

extract_npm_deps_hash() {
  local buildOutput="$1"
  local hash

  hash=$(echo "$buildOutput" | awk '
    /npm-deps\.drv/ { inNpmDeps = 1; next }
    inNpmDeps && /got:[[:space:]]*sha256-/ {
      if (match($0, /sha256-[A-Za-z0-9+/=]+/)) {
        print substr($0, RSTART, RLENGTH)
        exit
      }
    }
  ')

  if [[ -z "$hash" ]]; then
    hash=$(echo "$buildOutput" | sed -n 's/.*got:[[:space:]]*\(sha256-[A-Za-z0-9+/=]*\).*/\1/p' | head -1)
  fi

  echo "$hash"
}

SKIP_NPM_HASH=false
REFRESH_HASHES=false
CHECK_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --skip-npm-hash)
      SKIP_NPM_HASH=true
      ;;
    --refresh-hashes)
      REFRESH_HASHES=true
      ;;
    --check-only)
      CHECK_ONLY=true
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--skip-npm-hash] [--refresh-hashes] [--check-only]" >&2
      exit 1
      ;;
  esac
done

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

if [[ "$latestVersion" == "$currentVersion" ]] && [[ "$REFRESH_HASHES" != "true" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

if [[ "$CHECK_ONLY" == "true" ]]; then
  echo "Update available: $currentVersion -> $latestVersion"
  exit 0
fi

targetVersion="$latestVersion"
if [[ "$targetVersion" == "$currentVersion" ]]; then
  echo "Refreshing hashes for current version $targetVersion..."
else
  echo "Updating to version $targetVersion..."
fi

# Prefetch npm tarball
echo "Prefetching npm tarball source..."
NPM_URL="https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${targetVersion}.tgz"
echo "  URL: $NPM_URL"

SOURCE_HASH=$(nix store prefetch-file --json --name "claude-code-${targetVersion}.tgz" --unpack "$NPM_URL" | jq -r '.hash')

if [[ -z "$SOURCE_HASH" ]] || [[ "$SOURCE_HASH" == "null" ]]; then
  echo "Error: Failed to get source hash" >&2
  exit 1
fi

echo "Source hash: $SOURCE_HASH"

# Download and update package-lock.json
echo "Updating package-lock.json..."
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

curl -sL "$NPM_URL" | tar -xz -C "$TEMP_DIR"

if [[ -f "$TEMP_DIR/package/package-lock.json" ]]; then
  cp "$TEMP_DIR/package/package-lock.json" "$scriptDir/package-lock.json"
  echo "✅ Updated package-lock.json from upstream tarball"
else
  echo "ℹ️  package-lock.json not found in upstream tarball, generating from package.json..."
  (
    cd "$TEMP_DIR/package"
    npm install --package-lock-only --ignore-scripts --no-audit --no-fund >/dev/null
  )

  if [[ -f "$TEMP_DIR/package/package-lock.json" ]]; then
    cp "$TEMP_DIR/package/package-lock.json" "$scriptDir/package-lock.json"
    echo "✅ Generated and updated package-lock.json"
  else
    echo "⚠️  Warning: Failed to generate package-lock.json"
    echo "   You may need to update it manually"
  fi
fi

# Create backup
cp "$packageFile" "${packageFile}.bak"

# Update version
if [[ "$targetVersion" != "$currentVersion" ]]; then
  sed -i "s/version = \"$currentVersion\"/version = \"$targetVersion\"/" "$packageFile"
fi

# Update source hash
sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$SOURCE_HASH\"|" "$packageFile"

# Ensure URL uses version variable (don't hardcode version in URL)
# If URL was hardcoded, restore it to use the variable
sed -i "s|claude-code-[0-9][0-9.]*\.tgz|claude-code-\${finalAttrs.version}.tgz|" "$packageFile"

existingNpmDepsHash=$(grep -E '^\s*npmDepsHash\s*=' "$packageFile" | sed -E 's/.*npmDepsHash\s*=\s*"([^"]+)".*/\1/' | head -1 || true)
NPM_DEPS_HASH=""

if [[ "$SKIP_NPM_HASH" == "true" ]]; then
  echo "Skipping npmDepsHash computation (--skip-npm-hash flag set)"
else
  echo "Computing npmDepsHash..."

  FAKE_NPM_DEPS_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  sed -i "s|npmDepsHash = \"sha256-[^\"]*\"|npmDepsHash = \"$FAKE_NPM_DEPS_HASH\"|" "$packageFile"

  repoRoot="$(cd "$scriptDir/../.." && pwd)"
  SYSTEM="${NIX_SYSTEM:-$(nix eval --impure --expr 'builtins.currentSystem' 2>/dev/null || echo "x86_64-linux")}"

  BUILD_OUTPUT=""
  for build_cmd in \
    "nix build --no-link 'path:${repoRoot}#packages.${SYSTEM}.${targetAttr}' 2>&1" \
    "nix build --no-link 'path:${repoRoot}#${targetAttr}' 2>&1"
  do
    set +e
    BUILD_OUTPUT=$(eval "$build_cmd")
    BUILD_EXIT=$?
    set -e

    if [[ $BUILD_EXIT -eq 0 ]]; then
      break
    fi

    NPM_DEPS_HASH=$(extract_npm_deps_hash "$BUILD_OUTPUT")
    if [[ -n "$NPM_DEPS_HASH" ]]; then
      break
    fi
  done

  if [[ -n "$NPM_DEPS_HASH" ]]; then
    sed -i "s|npmDepsHash = \"$FAKE_NPM_DEPS_HASH\"|npmDepsHash = \"$NPM_DEPS_HASH\"|" "$packageFile"
    echo "✅ Updated npmDepsHash: $NPM_DEPS_HASH"
  else
    if [[ -n "$existingNpmDepsHash" ]]; then
      sed -i "s|npmDepsHash = \"$FAKE_NPM_DEPS_HASH\"|npmDepsHash = \"$existingNpmDepsHash\"|" "$packageFile"
    fi
    echo "⚠️  Warning: Could not automatically determine npmDepsHash"
    echo "   Build output saved to: ${packageFile}.build-error.log"
    echo "$BUILD_OUTPUT" > "${packageFile}.build-error.log"
  fi
fi

echo ""
echo "✅ Updated claude-code package metadata"
echo ""
echo "Changes:"
if [[ "$targetVersion" != "$currentVersion" ]]; then
  echo "  Version: $currentVersion -> $targetVersion"
else
  echo "  Version: $currentVersion (unchanged)"
fi
echo "  Source hash: $SOURCE_HASH"
if [[ -n "$NPM_DEPS_HASH" ]]; then
  echo "  npmDepsHash: $NPM_DEPS_HASH"
fi
echo ""
echo "Please review the changes:"
echo "  git diff $packageFile"
echo "  git diff $scriptDir/package-lock.json"
echo ""
echo "Backup saved to: ${packageFile}.bak"
