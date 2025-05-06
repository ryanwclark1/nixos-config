#!/usr/bin/env bash
set -euo pipefail

output_file="sources.nix"

declare -A platforms=(
  [x86_64-linux]='linux-x64'
  [aarch64-linux]='linux-arm64'
  [x86_64-darwin]='darwin-x64'
  [aarch64-darwin]='darwin-arm64'
)

declare -A urls
declare -A hashes

version=""

# Function: Read existing version from sources.nix if it exists
get_existing_version() {
  if [[ -f "$output_file" ]]; then
    grep 'version =' "$output_file" | sed -n 's/.*"\(.*\)".*/\1/p'
  else
    echo ""
  fi
}

existing_version=$(get_existing_version)

echo "Fetching latest version info from Cursor API..."

for platform in "${!platforms[@]}"; do
  api_platform="${platforms[$platform]}"
  response=$(curl -s "https://api2.cursor.sh/updates/api/download/stable/$api_platform/cursor")

  if [[ -z "$response" ]]; then
    echo "❌ Failed to fetch version info for $platform"
    exit 1
  fi

  this_version=$(echo "$response" | jq -r '.version')
  url=$(echo "$response" | jq -r '.downloadUrl')

  if [[ -z "$version" ]]; then
    version="$this_version"
  elif [[ "$version" != "$this_version" ]]; then
    echo "❌ Version mismatch across platforms: $version vs $this_version on $platform"
    exit 1
  fi

  if [[ -z "$url" ]]; then
    echo "❌ No download URL found for $platform"
    exit 1
  fi

  # Check URL is downloadable
  if ! curl --output /dev/null --silent --head --fail "$url"; then
    echo "❌ URL not reachable for $platform: $url"
    exit 1
  fi

  # Prefetch and hash
  source=$(nix-prefetch-url "$url" --name "cursor-$version-$platform")
  hash=$(nix-hash --to-sri --type sha256 "$source")

  urls[$platform]="$url"
  hashes[$platform]="$hash"
done

# Check if version is already current
if [[ "$version" == "$existing_version" ]]; then
  echo "🔁 No update: version $version is already in $output_file"
  exit 0
fi

# Write to sources.nix
{
  echo "let"
  echo "  pname = \"cursor\";"
  echo "  version = \"$version\";"
  echo ""
  echo "  inherit (stdenvNoCC) hostPlatform;"
  echo ""
  echo "  sources = {"

  for platform in "${!platforms[@]}"; do
    url="${urls[$platform]}"
    hash="${hashes[$platform]}"
    echo "    $platform = fetchurl {"
    echo "      url = \"$url\";"
    echo "      hash = \"$hash\";"
    echo "    };"
  done

  echo "  };"
  echo ""
  echo "in"
  echo "  sources.\${hostPlatform.system}"
} > "$output_file"

echo "✅ sources.nix updated to version $version"
