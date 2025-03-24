#!/usr/bin/env bash

set -eu -o pipefail
# Get latest API for packages, store so we only make one request

latest=$(curl -s "https://api.multiviewer.app/api/v1/releases/latest/")

# From the downloaded JSON extract the url, version and id
link=$(echo $latest | jq -r '.downloads[] | select(.platform=="linux_deb").url')
id=$(echo $latest | jq -r '.downloads[] | select(.platform=="linux_deb").id')
version=$(echo $latest | jq -r '.version')

# Pre-calculate package hash
hash=$(nix-prefetch-url --type sha256 $link)

echo ""
echo "id = \"$id\";"
echo "version = \"$version\";"
echo "src = pkgs.fetchurl {"
echo "  url = \"https://releases.multiviewer.dev/download/\${id}/multiviewer-for-f1_\${version}_amd64.deb\";"
echo "  sha256 = \"$hash\";"
echo "};"