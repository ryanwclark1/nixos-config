#!/usr/bin/env bash

# Function to get latest version from GitHub releases
get_latest_version() {
    curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Function to get hashes
get_hashes() {
    local version=$1

    # Get source hash
    local src_hash=$(nix-prefetch-url --unpack https://github.com/astral-sh/uv/archive/refs/tags/${version}.tar.gz)
    src_hash="sha256-$(nix hash convert --hash-algo sha256 --to base64 $src_hash)"

    # Create temporary nix file for cargo hash
    cat > temp.nix << EOF
{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.fetchCargoTarball {
  src = pkgs.fetchFromGitHub {
    owner = "astral-sh";
    repo = "uv";
    rev = "refs/tags/${version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
  name = "uv-${version}";
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}
EOF

    # Get cargo hash
    local cargo_hash=$(nix-build temp.nix 2>&1 | grep 'got:' | tail -n1 | awk '{print $2}')
    rm temp.nix

    echo "${src_hash} ${cargo_hash}"
}

# Function to update the overlay file
update_overlay() {
    local version=$1
    local src_hash=$2
    local cargo_hash=$3
    local overlay_file="uv-overlay.nix"

    cat > "${overlay_file}" << EOF
final: prev: {
  uv = prev.uv.overrideAttrs (oldAttrs: {
    version = "${version}";
    src = prev.fetchFromGitHub {
      owner = "astral-sh";
      repo = "uv";
      rev = "refs/tags/\${oldAttrs.version}";
      hash = "${src_hash}";
    };
    cargoDeps = prev.rustPlatform.fetchCargoTarball {
      inherit (oldAttrs) src;
      name = "uv-\${oldAttrs.version}";
      hash = "${cargo_hash}";
    };
  });
}
EOF
}

# Main execution
echo "Checking for latest uv version..."
LATEST_VERSION=$(get_latest_version)
echo "Latest version: ${LATEST_VERSION}"

echo "Getting hashes..."
read src_hash cargo_hash <<< $(get_hashes "${LATEST_VERSION}")
echo "Source hash: ${src_hash}"
echo "Cargo hash: ${cargo_hash}"

echo "Updating overlay..."
update_overlay "${LATEST_VERSION}" "${src_hash}" "${cargo_hash}"
echo "Overlay updated successfully!"