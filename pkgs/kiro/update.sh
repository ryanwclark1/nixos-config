#!/usr/bin/env bash

set -euo pipefail

# Fetch metadata from Kiro's API
echo "Fetching latest Kiro version metadata..."
metadata=$(curl -s "https://prod.download.desktop.kiro.dev/stable/metadata-linux-x64-stable.json")

# Extract version and URL
version=$(echo "$metadata" | jq -r '.currentRelease')
# Get the first release entry that contains the tar.gz file
url=$(echo "$metadata" | jq -r '.releases[] | select(.updateTo.url | contains(".tar.gz")) | .updateTo.url' | head -n1)

echo "Latest version: $version"
echo "Download URL: $url"

# Get the SHA256 hash
echo "Fetching SHA256 hash..."
sha256=$(nix-prefetch-url "$url" 2>/dev/null | tail -n1)

echo "SHA256: $sha256"

# Update the default.nix file
echo "Updating default.nix..."
sed -i "s/version = \".*\";/version = \"$version\";/" "$(dirname "$0")/default.nix"
sed -i "s|url = \".*\";|url = \"$url\";|" "$(dirname "$0")/default.nix"
sed -i "s/sha256 = \".*\";/sha256 = \"$sha256\";/" "$(dirname "$0")/default.nix"

echo "Updated Kiro to version $version"