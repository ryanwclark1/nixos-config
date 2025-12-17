#!/usr/bin/env bash
# Helper script to find the latest version of a package in nixpkgs
# Usage: ./find-package-version.sh <package-name>

set -euo pipefail

PACKAGE_NAME="${1:-}"

if [[ -z "$PACKAGE_NAME" ]]; then
  echo "Usage: $0 <package-name>"
  echo "Example: $0 code-cursor"
  exit 1
fi

echo "🔍 Finding version information for: $PACKAGE_NAME"
echo ""

# Method 1: Direct version evaluation
echo "1️⃣  Current version in nixpkgs:"
VERSION=$(nix eval "nixpkgs#$PACKAGE_NAME.version" 2>/dev/null | tr -d '"' || echo "Not found")
echo "   Version: $VERSION"
echo ""

# Method 2: Get package file location
echo "2️⃣  Package file location:"
POSITION=$(nix eval --raw "nixpkgs#$PACKAGE_NAME.meta.position" 2>/dev/null | cut -d: -f1 || echo "")
if [[ -n "$POSITION" ]]; then
  echo "   File: $POSITION"
  # Extract relative path from nix store path
  REL_PATH=$(echo "$POSITION" | sed -n 's|.*/nixpkgs/\(.*\)|\1|p')
  if [[ -n "$REL_PATH" ]]; then
    echo "   GitHub: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/$REL_PATH"
  else
    # Try to extract from the path structure (by-name format)
    PKG_NAME_FIRST=$(echo "$PACKAGE_NAME" | cut -c1)
    PKG_NAME_TWO=$(echo "$PACKAGE_NAME" | cut -c1-2)
    echo "   GitHub: https://github.com/NixOS/nixpkgs/tree/nixos-unstable/pkgs/by-name/$PKG_NAME_FIRST/$PKG_NAME_TWO/$PACKAGE_NAME"
  fi
else
  echo "   Could not determine file location"
fi
echo ""

# Method 3: Check for update script
echo "3️⃣  Update script:"
UPDATE_SCRIPT=$(nix eval --raw "nixpkgs#$PACKAGE_NAME.passthru.updateScript or null" 2>/dev/null || echo "null")
if [[ -n "$POSITION" ]] && [[ -f "$(dirname "$POSITION")/update.sh" ]]; then
  UPDATE_SCRIPT_PATH="$(dirname "$POSITION")/update.sh"
  echo "   ✅ Found: $UPDATE_SCRIPT_PATH"
  echo "   This script shows how to fetch the latest version"
elif [[ "$UPDATE_SCRIPT" != "null" ]] && [[ "$UPDATE_SCRIPT" != "" ]]; then
  echo "   ✅ Found: $UPDATE_SCRIPT"
else
  echo "   ❌ No update script found"
fi
echo ""

# Method 4: Package metadata
echo "4️⃣  Package metadata:"
echo "   Homepage: $(nix eval --raw "nixpkgs#$PACKAGE_NAME.meta.homepage or \"N/A\"" 2>/dev/null | tr -d '"' || echo "N/A")"
echo "   Description: $(nix eval --raw "nixpkgs#$PACKAGE_NAME.meta.description or \"N/A\"" 2>/dev/null | tr -d '"' || echo "N/A")"
echo ""

# Method 5: Show how to check GitHub
echo "5️⃣  To check on GitHub:"
# Extract from position if available, otherwise guess from package name
if [[ -n "$POSITION" ]]; then
  # Extract the by-name path from the store path
  BY_NAME_PATH=$(echo "$POSITION" | grep -o 'pkgs/by-name/[^/]*/[^/]*/[^/]*' || echo "")
  if [[ -n "$BY_NAME_PATH" ]]; then
    echo "   https://github.com/NixOS/nixpkgs/tree/nixos-unstable/$BY_NAME_PATH"
  else
    PKG_NAME_FIRST=$(echo "$PACKAGE_NAME" | cut -c1)
    PKG_NAME_TWO=$(echo "$PACKAGE_NAME" | cut -c1-2)
    echo "   https://github.com/NixOS/nixpkgs/tree/nixos-unstable/pkgs/by-name/$PKG_NAME_FIRST/$PKG_NAME_TWO/$PACKAGE_NAME"
  fi
else
  PKG_NAME_FIRST=$(echo "$PACKAGE_NAME" | cut -c1)
  PKG_NAME_TWO=$(echo "$PACKAGE_NAME" | cut -c1-2)
  echo "   https://github.com/NixOS/nixpkgs/tree/nixos-unstable/pkgs/by-name/$PKG_NAME_FIRST/$PKG_NAME_TWO/$PACKAGE_NAME"
fi
echo ""

# Method 6: Search.nixos.org
echo "6️⃣  Search online:"
echo "   https://search.nixos.org/packages?query=$PACKAGE_NAME"
echo ""

echo "💡 Tips:"
echo "   - Check the update.sh script to see how the maintainer fetches latest versions"
echo "   - Look at the package.nix file to see the version and source URLs"
echo "   - Check the upstream project's releases/changelog for latest versions"
echo "   - Use 'nix search nixpkgs <name>' to search for packages"

