#!/usr/bin/env bash

set -eu -o pipefail

# Gemini CLI Update Script
# Similar to multiviewer-update.sh and nvfetcher workflow
# Updates the gemini-cli-override.nix file with latest version and hash

OVERRIDE_FILE="$HOME/nixos-config/home/features/ai/gemini-cli-override.nix"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat << EOF
Gemini CLI Update Script

Usage: $(basename "$0") [version|latest]

Examples:
  $(basename "$0")              # Update to latest release
  $(basename "$0") latest       # Update to latest release  
  $(basename "$0") 0.3.0        # Update to specific version

This script will:
1. Fetch version info from GitHub API
2. Calculate the correct hash using nix-prefetch-url
3. Update the override file with new version and hash
4. Display the changes made
EOF
}

# Get latest release from GitHub API
get_latest_release() {
    echo "Fetching latest release from GitHub API..." >&2
    local latest_json
    latest_json=$(curl -sf https://api.github.com/repos/google-gemini/gemini-cli/releases/latest) || {
        echo "Error: Failed to fetch latest release" >&2
        return 1
    }
    
    local tag_name version published_at
    tag_name=$(echo "$latest_json" | jq -r '.tag_name')
    version=$(echo "$tag_name" | sed 's/^v//')
    published_at=$(echo "$latest_json" | jq -r '.published_at' | cut -d'T' -f1)
    
    echo "Latest release: $version (published $published_at)" >&2
    echo "$version"
}

# Get hash for specific version
get_version_hash() {
    local version="$1"
    
    echo "Calculating hash for version $version..." >&2
    
    # Validate version format
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format. Use semantic versioning (e.g., 0.3.0)" >&2
        return 1
    fi
    
    local url="https://github.com/google-gemini/gemini-cli/archive/v${version}.tar.gz"
    
    # Use nix-prefetch-url to get the hash (similar to multiviewer approach)
    local hash
    hash=$(nix-prefetch-url --unpack "$url" 2>/dev/null) || {
        echo "Error: Failed to fetch or calculate hash for version $version" >&2
        echo "URL: $url" >&2
        return 1
    }
    
    echo "$hash"
}

# Update the override file (similar to how multiviewer outputs the result)
update_override_file() {
    local version="$1"
    local hash="$2"
    
    if [[ ! -f "$OVERRIDE_FILE" ]]; then
        echo "Error: Override file not found at $OVERRIDE_FILE" >&2
        echo "Please create the gemini-cli-override.nix file first" >&2
        return 1
    fi
    
    echo "Updating override file..." >&2
    
    # Create backup
    cp "$OVERRIDE_FILE" "${OVERRIDE_FILE}.backup"
    
    # Update version and hash (ensure sha256- prefix is included)
    sed -i "s/version = \".*\";/version = \"$version\";/" "$OVERRIDE_FILE"
    sed -i "s/hash = \"sha256-.*\";/hash = \"sha256-$hash\";/" "$OVERRIDE_FILE"
    
    # Update the comment to reflect current version being checked
    sed -i "s/# Use: gemini-cli-version check .*/# Use: gemini-cli-version check $version/" "$OVERRIDE_FILE"
    
    echo "" >&2
    echo "✅ Updated gemini-cli-override.nix:" >&2
    echo "   Version: $version" >&2
    echo "   Hash: $hash" >&2
    echo "   Backup: ${OVERRIDE_FILE}.backup" >&2
    echo "" >&2
    
    # Output the Nix attribute format (similar to multiviewer)
    echo "Updated Nix attributes:"
    echo "version = \"$version\";"
    echo "hash = \"sha256-$hash\";"
    echo ""
    echo "Note: Patches from nixpkgs are preserved. If build fails, consider removing patches."
}

# Show current configuration
show_current() {
    if [[ -f "$OVERRIDE_FILE" ]]; then
        local current_version current_hash
        current_version=$(grep 'version = ' "$OVERRIDE_FILE" | sed 's/.*version = "\(.*\)";.*/\1/' || echo "unknown")
        current_hash=$(grep 'hash = ' "$OVERRIDE_FILE" | sed 's/.*hash = "\(.*\)";.*/\1/' || echo "unknown")
        
        echo "Current configuration:"
        echo "  Version: $current_version"
        echo "  Hash: $current_hash"
    else
        echo "No override file found (using nixpkgs default)"
    fi
}

# Main function
main() {
    local target="${1:-latest}"
    
    case "$target" in
        "help"|"-h"|"--help")
            usage
            exit 0
            ;;
        "current")
            show_current
            exit 0
            ;;
        "latest"|"")
            echo "Updating to latest release..."
            local version
            version=$(get_latest_release)
            local hash
            hash=$(get_version_hash "$version")
            update_override_file "$version" "$hash"
            ;;
        *)
            # Assume it's a specific version
            if [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "Updating to version $target..."
                local hash
                hash=$(get_version_hash "$target")
                update_override_file "$target" "$hash"
            else
                echo "Error: Invalid version '$target'. Use format like '0.3.0' or 'latest'" >&2
                usage
                exit 1
            fi
            ;;
    esac
}

main "$@"