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

# Get latest release from GitHub API that matches our version format
get_latest_release() {
    echo "Fetching latest compatible release from GitHub API..." >&2

    # Get all release tag names and filter for valid semantic versions
    local releases_tags
    releases_tags=$(curl -sf https://api.github.com/repos/google-gemini/gemini-cli/releases | jq -r '.[].tag_name') || {
        echo "Error: Failed to fetch releases" >&2
        return 1
    }

    # Process each tag to find the first valid semantic version
    local found_version=""
    local skipped_count=0

    while IFS= read -r tag_name; do
        local version
        version=$(echo "$tag_name" | sed 's/^v//')

        # Check if version matches our semantic versioning pattern
        if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            found_version="$version"
            break
        else
            echo "Skipping incompatible version: $version" >&2
            ((skipped_count++))
        fi
    done <<< "$releases_tags"

    if [[ -z "$found_version" ]]; then
        echo "Error: No compatible release found matching version format ^[0-9]+\.[0-9]+\.[0-9]+$" >&2
        return 1
    fi

    # Get publication date for the found version
    local published_at
    published_at=$(curl -sf "https://api.github.com/repos/google-gemini/gemini-cli/releases/tags/v${found_version}" | jq -r '.published_at' | cut -d'T' -f1)

    echo "Found compatible release: $found_version (published $published_at)" >&2
    if [[ $skipped_count -gt 0 ]]; then
        echo "Note: Skipped $skipped_count newer pre-release/beta versions" >&2
    fi
    echo "$found_version"
}

# Get hash for specific version using nix-prefetch-github for fetchFromGitHub compatibility
get_version_hash() {
    local version="$1"

    echo "Calculating hash for version $version..." >&2

    # Validate version format
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format. Use semantic versioning (e.g., 0.3.0)" >&2
        return 1
    fi

    # Use nix-prefetch-github for fetchFromGitHub compatibility
    local sri_hash
    sri_hash=$(nix-prefetch-github google-gemini gemini-cli --rev "v${version}" 2>/dev/null | jq -r '.sha256') || {
        echo "Error: Failed to fetch or calculate hash for version $version" >&2
        return 1
    }

    # Convert to SRI format
    sri_hash=$(nix hash to-sri "sha256:$sri_hash") || {
        echo "Error: Failed to convert to SRI format" >&2
        return 1
    }

    echo "$sri_hash"
}

# Get npm dependencies hash for specific version
get_npm_deps_hash() {
    local version="$1"

    echo "Calculating npm dependencies hash for version $version..." >&2
    echo "Warning: npm deps hash calculation is complex - may need manual verification" >&2

    # For now, return a placeholder that will need to be updated by build error
    # This is because npmDepsHash calculation requires actually running the build
    echo "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
}

# Update the override file (similar to how multiviewer outputs the result)
update_override_file() {
    local version="$1"
    local hash="$2"
    local npm_hash="$3"
    local output_file="$SCRIPT_DIR/gemini-cli-version.txt"

    if [[ ! -f "$OVERRIDE_FILE" ]]; then
        echo "Error: Override file not found at $OVERRIDE_FILE" >&2
        echo "Please create the gemini-cli-override.nix file first" >&2
        return 1
    fi

    echo "Updating override file..." >&2

    # Create backup
    cp "$OVERRIDE_FILE" "${OVERRIDE_FILE}.backup"

    # Update version, source hash, and npm deps hash
    sed -i "s/version = ".*";/version = \"$version\";/" "$OVERRIDE_FILE"
    escaped_hash=$(echo "$hash" | sed 's/[\/&]/\\&/g')
    sed -i "s/hash = \"sha256-.*\";/hash = \"$escaped_hash\";/" "$OVERRIDE_FILE"
    escaped_npm_hash=$(echo "$npm_hash" | sed 's/[\/&]/\\&/g')
    sed -i "s/npmDepsHash = \"sha256-.*\";/npmDepsHash = \"$escaped_npm_hash\";/" "$OVERRIDE_FILE"

    # Update the comment to reflect current version being checked
    sed -i "s/# Use: gemini-cli-version check .*/# Use: gemini-cli-version check $version/" "$OVERRIDE_FILE"

    echo "" >&2
    echo "✅ Updated gemini-cli-override.nix:" >&2
    echo "   Version: $version" >&2
    echo "   Hash: $hash" >&2
    echo "   Backup: ${OVERRIDE_FILE}.backup" >&2
    echo "" >&2

    # Output the Nix attribute format to a file
    echo "Writing version info to $output_file" >&2
    {
        echo "version = \"$version\";"
        echo "hash = \"$hash\";"
    } > "$output_file"

    # Output the Nix attribute format (similar to multiviewer)
    echo "Updated Nix attributes:"
    cat "$output_file"
    echo ""
    echo "Note: npm deps hash may need manual verification via build error messages."
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
            local hash npm_hash
            hash=$(get_version_hash "$version")
            npm_hash=$(get_npm_deps_hash "$version")
            update_override_file "$version" "$hash" "$npm_hash"
            ;;
        *)
            # Assume it's a specific version
            if [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "Updating to version $target..."
                local hash npm_hash
                hash=$(get_version_hash "$target")
                npm_hash=$(get_npm_deps_hash "$target")
                update_override_file "$target" "$hash" "$npm_hash"
            else
                echo "Error: Invalid version '$target'. Use format like '0.3.0' or 'latest'" >&2
                usage
                exit 1
            fi
            ;;
    esac
}

main "$@"