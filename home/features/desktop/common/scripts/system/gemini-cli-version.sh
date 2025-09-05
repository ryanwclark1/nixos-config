#!/usr/bin/env bash

# Gemini CLI Version and Hash Manager
# Similar to multiviewer and nvfetcher for VSCode extensions

set -euo pipefail

GEMINI_OVERRIDE_FILE="$HOME/nixos-config/home/features/ai/gemini-cli-override.nix"

usage() {
    cat << EOF
Gemini CLI Version and Hash Manager

Usage: $(basename "$0") <command> [version]

Commands:
  current                       Show current configured version and hash
  latest                        Show latest available release
  check <version>               Get hash for specific version
  update <version>              Update override file with new version and hash
  releases                      List recent releases
  compare                       Compare current vs latest

Examples:
  $(basename "$0") current                    # Show current configuration
  $(basename "$0") latest                     # Show latest release info
  $(basename "$0") check 0.3.0               # Get hash for version 0.3.0
  $(basename "$0") update 0.3.0              # Update to version 0.3.0
  $(basename "$0") releases                   # List recent releases

Similar to multiviewer and nvfetcher workflow for managing package versions.
EOF
}

# Get current configured version and hash from override file
get_current_config() {
    if [[ ! -f "$GEMINI_OVERRIDE_FILE" ]]; then
        echo "No override file found at $GEMINI_OVERRIDE_FILE"
        return 1
    fi
    
    local version hash npm_hash
    version=$(grep 'version = ' "$GEMINI_OVERRIDE_FILE" | sed 's/.*version = "\(.*\)";.*/\1/' || echo "unknown")
    hash=$(grep 'hash = ' "$GEMINI_OVERRIDE_FILE" | sed 's/.*hash = "\(.*\)";.*/\1/' || echo "unknown")
    npm_hash=$(grep 'npmDepsHash = ' "$GEMINI_OVERRIDE_FILE" | sed 's/.*npmDepsHash = "\(.*\)";.*/\1/' || echo "unknown")
    
    echo "Current Configuration:"
    echo "  Version: $version"
    echo "  Source Hash: $hash"
    echo "  NPM Deps Hash: $npm_hash"
    echo "  File: $GEMINI_OVERRIDE_FILE"
}

# Get latest release from GitHub API
get_latest_release() {
    local release_info
    release_info=$(curl -sf https://api.github.com/repos/google-gemini/gemini-cli/releases/latest 2>/dev/null) || {
        echo "Error: Unable to fetch latest release from GitHub API" >&2
        return 1
    }
    
    local version tag_name published_at
    tag_name=$(echo "$release_info" | jq -r '.tag_name')
    version=$(echo "$tag_name" | sed 's/^v//')
    published_at=$(echo "$release_info" | jq -r '.published_at' | cut -d'T' -f1)
    
    echo "Latest Release:"
    echo "  Version: $version"
    echo "  Tag: $tag_name"  
    echo "  Published: $published_at"
    
    # Calculate hash for latest version
    echo ""
    echo "Calculating hash for latest version..."
    local hash
    hash=$(get_version_hash "$version")
    echo "  Source Hash: $hash"
}

# Get hash for specific version
get_version_hash() {
    local version="$1"
    
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format. Use semantic versioning (e.g., 0.3.0)" >&2
        return 1
    fi
    
    local url="https://github.com/google-gemini/gemini-cli/archive/v${version}.tar.gz"
    
    # Use nix-prefetch-url to get the hash
    local hash
    hash=$(nix-prefetch-url --unpack "$url" 2>/dev/null) || {
        echo "Error: Unable to fetch or calculate hash for version $version" >&2
        echo "URL: $url" >&2
        return 1
    }
    
    echo "$hash"
}

# Check specific version (show hash and info)
check_version() {
    local version="$1"
    
    echo "Checking version $version..."
    echo ""
    
    # Try to get release info for this version
    local release_info
    release_info=$(curl -sf "https://api.github.com/repos/google-gemini/gemini-cli/releases/tags/v${version}" 2>/dev/null) || {
        echo "Warning: Could not fetch release info for v$version (might not exist)" >&2
    }
    
    if [[ -n "${release_info:-}" ]]; then
        local published_at name
        published_at=$(echo "$release_info" | jq -r '.published_at' | cut -d'T' -f1)
        name=$(echo "$release_info" | jq -r '.name')
        echo "Release Info:"
        echo "  Name: $name"
        echo "  Published: $published_at"
        echo ""
    fi
    
    echo "Calculating hash..."
    local hash
    hash=$(get_version_hash "$version")
    
    echo "Version $version:"
    echo "  Source Hash: $hash"
    echo ""
    echo "Override file entry:"
    echo "  version = \"$version\";"
    echo "  hash = \"$hash\";"
}

# List recent releases
list_releases() {
    echo "Recent Releases:"
    echo "================"
    
    local releases
    releases=$(curl -sf https://api.github.com/repos/google-gemini/gemini-cli/releases 2>/dev/null) || {
        echo "Error: Unable to fetch releases from GitHub API" >&2
        return 1
    }
    
    echo "$releases" | jq -r '.[] | select(.prerelease == false) | "\(.tag_name) - \(.published_at[:10]) - \(.name)"' | head -10
}

# Compare current vs latest
compare_versions() {
    echo "Version Comparison:"
    echo "==================="
    echo ""
    
    # Get current
    if [[ -f "$GEMINI_OVERRIDE_FILE" ]]; then
        local current_version
        current_version=$(grep 'version = ' "$GEMINI_OVERRIDE_FILE" | sed 's/.*version = "\(.*\)";.*/\1/' 2>/dev/null || echo "unknown")
        echo "Current: $current_version"
    else
        echo "Current: No override (using nixpkgs default)"
    fi
    
    # Get latest
    local latest_info latest_version
    latest_info=$(curl -sf https://api.github.com/repos/google-gemini/gemini-cli/releases/latest 2>/dev/null) || {
        echo "Latest: Unable to fetch" >&2
        return 1
    }
    latest_version=$(echo "$latest_info" | jq -r '.tag_name' | sed 's/^v//')
    echo "Latest:  $latest_version"
    
    echo ""
    if [[ "$current_version" == "$latest_version" ]]; then
        echo "✅ You're using the latest version!"
    else
        echo "⚠️  Update available: $current_version → $latest_version"
    fi
}

# Update override file
update_override() {
    local new_version="$1"
    
    echo "Updating to version $new_version..."
    
    # Validate version format
    if [[ ! "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format. Use semantic versioning (e.g., 0.3.0)" >&2
        return 1
    fi
    
    # Calculate hash
    echo "Calculating hash for version $new_version..."
    local hash
    hash=$(get_version_hash "$new_version") || return 1
    
    # Check if override file exists
    if [[ ! -f "$GEMINI_OVERRIDE_FILE" ]]; then
        echo "Creating new override file at $GEMINI_OVERRIDE_FILE"
        mkdir -p "$(dirname "$GEMINI_OVERRIDE_FILE")"
        cat > "$GEMINI_OVERRIDE_FILE" << EOF
{
  pkgs,
  lib,
  ...
}:

{
  # Override gemini-cli package with custom version
  home.packages = with pkgs; [
    (gemini-cli.overrideAttrs (oldAttrs: rec {
      version = "$new_version";
      
      src = pkgs.fetchFromGitHub {
        owner = "google-gemini";
        repo = "gemini-cli";
        tag = "v\${version}";
        hash = "$hash";
      };
      
      # Note: Update npmDepsHash if build fails
      # Run: nix-build '<nixpkgs>' -A gemini-cli
      # npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      
      # Remove patches if they're no longer needed in newer version
      patches = [];
    }))
  ];
}
EOF
    else
        # Update existing file
        echo "Updating existing override file..."
        cp "$GEMINI_OVERRIDE_FILE" "${GEMINI_OVERRIDE_FILE}.backup"
        
        sed -i "s/version = \".*\";/version = \"$new_version\";/" "$GEMINI_OVERRIDE_FILE"
        sed -i "s/hash = \"sha256-.*\";/hash = \"sha256-$hash\";/" "$GEMINI_OVERRIDE_FILE"
        sed -i "s/# Use: gemini-cli-version check .*/# Use: gemini-cli-version check $new_version/" "$GEMINI_OVERRIDE_FILE"
    fi
    
    echo ""
    echo "✅ Updated to version $new_version"
    echo "   Hash: $hash"
    echo "   File: $GEMINI_OVERRIDE_FILE"
    echo ""
    echo "Next steps:"
    echo "1. Import the override file in your Nix configuration"
    echo "2. Rebuild your configuration"
    echo "3. If build fails, update npmDepsHash with the suggested value"
}

# Main function
main() {
    local command="${1:-}"
    
    case "$command" in
        "current")
            get_current_config
            ;;
        "latest")
            get_latest_release
            ;;
        "check")
            if [[ $# -lt 2 ]]; then
                echo "Error: Version required for check command" >&2
                usage
                exit 1
            fi
            check_version "$2"
            ;;
        "update")
            if [[ $# -lt 2 ]]; then
                echo "Error: Version required for update command" >&2
                usage
                exit 1
            fi
            update_override "$2"
            ;;
        "releases")
            list_releases
            ;;
        "compare")
            compare_versions
            ;;
        "help"|"-h"|"--help"|"")
            usage
            ;;
        *)
            echo "Error: Unknown command '$command'" >&2
            usage
            exit 1
            ;;
    esac
}

main "$@"