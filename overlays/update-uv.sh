#!/usr/bin/env bash

# Get the source hash
echo "Fetching source hash..."
src_hash=$(nix-prefetch-github --rev refs/tags/0.5.10 astral-sh uv)
echo "Source hash obtained"

# Create a temporary Nix expression to get the cargo hash
cat > temp.nix << 'EOF'
{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.fetchCargoTarball {
  src = pkgs.fetchFromGitHub {
    owner = "astral-sh";
    repo = "uv";
    rev = "refs/tags/0.5.10";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
  name = "uv-0.5.10";
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}
EOF

echo "Fetching cargo hash..."
cargo_hash=$(nix-build temp.nix 2>&1 | grep 'got:' | tail -n1 | awk '{print $2}')
rm temp.nix

echo "=== Results ==="
echo "Source hash: $src_hash"
echo "Cargo hash: $cargo_hash"

