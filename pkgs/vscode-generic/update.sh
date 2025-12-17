#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl git nix
set -euo pipefail

# Script to update vscode-generic/generic.nix from nixpkgs
# This ensures we have the latest builder improvements and fixes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GENERIC_NIX="$SCRIPT_DIR/generic.nix"
DEFAULT_NIX="$SCRIPT_DIR/default.nix"

echo "Fetching latest vscode-generic/generic.nix from nixpkgs..."

# Fetch the latest generic.nix from nixpkgs
LATEST_GENERIC=$(curl -s "https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-unstable/pkgs/applications/editors/vscode/generic.nix")

if [[ -z "$LATEST_GENERIC" ]] || echo "$LATEST_GENERIC" | grep -q "404: Not Found"; then
  echo "❌ Error: Failed to fetch generic.nix from nixpkgs"
  exit 1
fi

# Calculate hashes
CURRENT_HASH=$(sha256sum "$GENERIC_NIX" 2>/dev/null | cut -d' ' -f1 || echo "")
NEW_HASH=$(echo "$LATEST_GENERIC" | sha256sum | cut -d' ' -f1)

if [[ "$CURRENT_HASH" == "$NEW_HASH" ]]; then
  echo "Already up to date: vscode-generic/generic.nix (hash: $CURRENT_HASH)"
  exit 0
fi

echo "📦 Updating generic.nix..."
echo "$LATEST_GENERIC" > "$GENERIC_NIX"

# Ensure default.nix exists and is correct
if [[ ! -f "$DEFAULT_NIX" ]] || ! grep -q "callPackage ./generic.nix" "$DEFAULT_NIX"; then
  echo "📝 Creating/updating default.nix..."
  cat > "$DEFAULT_NIX" << 'EOF'
# This file re-exports the generic.nix builder for VS Code-based applications
# It allows packages to use: callPackage ../vscode-generic { }
# instead of: callPackage ../vscode-generic/generic.nix { }

{
  callPackage,
  ...
}:

callPackage ./generic.nix { }
EOF
fi

echo "✅ Updated vscode-generic/generic.nix"
echo ""
echo "Changes:"
echo "  Hash: $CURRENT_HASH -> $NEW_HASH"
echo ""
echo "Please review the changes:"
echo "  git diff $GENERIC_NIX"

