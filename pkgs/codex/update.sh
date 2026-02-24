#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix
set -eu -o pipefail

# Get the directory where this script is located
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
packageFile="$scriptDir/default.nix"

extract_hash_from_build() {
  local buildOutput="$1"
  local hash

  hash=$(echo "$buildOutput" | awk '
    /vendor-staging\.drv|vendor\.drv/ { inVendor = 1; next }
    inVendor && /got:[[:space:]]*sha256-/ {
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

SKIP_CARGO_HASH=false
REFRESH_HASHES=false
for arg in "$@"; do
  case "$arg" in
    --skip-cargo-hash)
      SKIP_CARGO_HASH=true
      ;;
    --refresh-hashes)
      REFRESH_HASHES=true
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--skip-cargo-hash] [--refresh-hashes]" >&2
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

if [[ "$latestVersion" == "$currentVersion" ]] && [[ "$REFRESH_HASHES" != "true" ]]; then
  echo "Already up to date: $currentVersion"
  exit 0
fi

targetVersion="$latestVersion"
if [[ "$targetVersion" == "$currentVersion" ]]; then
  echo "Refreshing hashes for current version $targetVersion..."
else
  echo "Updating to version $targetVersion..."
fi

# Prefetch GitHub source archive using unpacked hash (matches fetchFromGitHub)
echo "Prefetching GitHub source..."
GITHUB_TAG="rust-v${targetVersion}"
echo "  Tag: $GITHUB_TAG"
GITHUB_TARBALL_URL="https://github.com/openai/codex/archive/refs/tags/${GITHUB_TAG}.tar.gz"
SOURCE_HASH=$(nix store prefetch-file --json --name "codex-${GITHUB_TAG}.tar.gz" --unpack "$GITHUB_TARBALL_URL" | jq -r '.hash')

if [[ -z "$SOURCE_HASH" ]] || [[ "$SOURCE_HASH" == "null" ]]; then
  echo "Error: Failed to get source hash from archive prefetch" >&2
  exit 1
fi

echo "Source hash: $SOURCE_HASH"

# Create backup
cp "$packageFile" "${packageFile}.bak"

# Update version
if [[ "$targetVersion" != "$currentVersion" ]]; then
  sed -i "s/version = \"$currentVersion\"/version = \"$targetVersion\"/" "$packageFile"
fi

# Ensure tag and changelog track the version field to avoid drift
sed -i 's|tag = "rust-v[^"]*"|tag = "rust-v${finalAttrs.version}"|' "$packageFile"
sed -i 's|changelog = "https://raw.githubusercontent.com/openai/codex/refs/tags/rust-v[^"]*/CHANGELOG.md"|changelog = "https://raw.githubusercontent.com/openai/codex/refs/tags/rust-v${finalAttrs.version}/CHANGELOG.md"|' "$packageFile"

# Update source hash
sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$SOURCE_HASH\"|" "$packageFile"

# Compute cargoHash automatically via a controlled mismatch
if [[ "$SKIP_CARGO_HASH" == "true" ]]; then
  CARGO_HASH=""
  echo "Skipping cargoHash computation (--skip-cargo-hash flag set)"
else
  echo "Computing cargoHash..."
  FAKE_CARGO_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  sed -i "s|cargoHash = \"[^\"]*\"|cargoHash = \"$FAKE_CARGO_HASH\"|" "$packageFile"

  repoRoot="$(cd "$scriptDir/../.." && pwd)"
  SYSTEM="${NIX_SYSTEM:-$(nix eval --impure --expr 'builtins.currentSystem' 2>/dev/null || echo "x86_64-linux")}"

  BUILD_OUTPUT=""
  CARGO_HASH=""
  for build_cmd in \
    "cd '$repoRoot' && nix build --no-link '.#packages.${SYSTEM}.codex' 2>&1" \
    "cd '$repoRoot' && nix build --no-link .#codex 2>&1" \
    "nix build --no-link -f '<nixpkgs>' -A codex 2>&1" \
    "nix-build --no-out-link -A codex 2>&1"
  do
    set +e
    BUILD_OUTPUT=$(eval "$build_cmd")
    BUILD_EXIT=$?
    set -e

    if [[ $BUILD_EXIT -eq 0 ]]; then
      break
    fi

    CARGO_HASH=$(extract_hash_from_build "$BUILD_OUTPUT")
    if [[ -n "$CARGO_HASH" ]]; then
      break
    fi
  done

  if [[ -n "$CARGO_HASH" ]]; then
    sed -i "s|cargoHash = \"$FAKE_CARGO_HASH\"|cargoHash = \"$CARGO_HASH\"|" "$packageFile"
    echo "✅ Updated cargoHash: $CARGO_HASH"
  else
    echo "⚠️  Warning: Could not automatically determine cargoHash"
    echo "   Build output saved to: ${packageFile}.build-error.log"
    echo "$BUILD_OUTPUT" > "${packageFile}.build-error.log"
  fi
fi

echo "✅ Updated codex package metadata"
echo ""
echo "Changes:"
if [[ "$targetVersion" != "$currentVersion" ]]; then
  echo "  Version: $currentVersion -> $targetVersion"
else
  echo "  Version: $currentVersion (unchanged)"
fi
echo "  Source hash: $SOURCE_HASH"
if [[ -n "$CARGO_HASH" ]]; then
  echo "  cargoHash: $CARGO_HASH"
fi
echo ""
echo "Please review the changes:"
echo "  git diff $packageFile"
echo ""
echo "Backup saved to: ${packageFile}.bak"
