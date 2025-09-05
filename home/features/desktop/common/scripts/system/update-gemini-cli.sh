#!/usr/bin/env bash

# Gemini CLI Version Updater
# Helper script to update gemini-cli version and calculate new hashes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_REMATCH[0]}")" && pwd)"
GEMINI_OVERRIDE_FILE="$HOME/nixos-config/home/features/ai/gemini-cli-override.nix"

usage() {
    cat << EOF
Gemini CLI Version Updater

Usage: $(basename "$0") <version|commit> [options]

Examples:
  $(basename "$0") 0.3.0                    # Update to version 0.3.0
  $(basename "$0") abcdef123                # Update to specific git commit
  $(basename "$0") latest                   # Update to latest release
  $(basename "$0") --check-current          # Show current configured version

This script will:
1. Fetch the source archive
2. Calculate the correct hash
3. Update the override file with new version and hash
4. Optionally test the build
EOF
}

# Get latest release version from GitHub
get_latest_version() {
    curl -sf https://api.github.com/repos/google-gemini/gemini-cli/releases/latest | \
        jq -r '.tag_name' | sed 's/^v//'
}

# Calculate hash for version
calculate_version_hash() {
    local version="$1"
    echo "Calculating hash for version $version..."
    
    local url="https://github.com/google-gemini/gemini-cli/archive/v${version}.tar.gz"
    nix-prefetch-url --unpack "$url" 2>/dev/null
}

# Calculate hash for git commit
calculate_commit_hash() {
    local commit="$1"
    echo "Calculating hash for commit $commit..."
    
    nix-prefetch-git --url https://github.com/google-gemini/gemini-cli.git --rev "$commit" --quiet | jq -r '.sha256'
}

# Update the override file
update_override_file() {
    local version="$1"
    local hash="$2"
    local is_commit="${3:-false}"
    
    if [[ ! -f "$GEMINI_OVERRIDE_FILE" ]]; then
        echo "Error: Override file not found at $GEMINI_OVERRIDE_FILE" >&2
        exit 1
    fi
    
    echo "Updating override file..."
    
    # Create backup
    cp "$GEMINI_OVERRIDE_FILE" "${GEMINI_OVERRIDE_FILE}.backup"
    
    if [[ "$is_commit" == "true" ]]; then
        # Update for git commit
        sed -i "s/version = \".*\";/version = \"${version}-unstable-$(date +%Y-%m-%d)\";/" "$GEMINI_OVERRIDE_FILE"
        sed -i "s/tag = \"v.*\";/rev = \"${version}\";/" "$GEMINI_OVERRIDE_FILE"
    else
        # Update for version tag
        sed -i "s/version = \".*\";/version = \"${version}\";/" "$GEMINI_OVERRIDE_FILE"
        sed -i "s/rev = \".*\";/tag = \"v${version}\";/" "$GEMINI_OVERRIDE_FILE"
    fi
    
    # Update hash
    sed -i "s/hash = \"sha256-.*\";/hash = \"${hash}\";/" "$GEMINI_OVERRIDE_FILE"
    
    echo "Updated $GEMINI_OVERRIDE_FILE"
    echo "Backup saved as ${GEMINI_OVERRIDE_FILE}.backup"
}

# Test build
test_build() {
    echo "Testing build..."
    if nix-build '<nixpkgs>' -A gemini-cli --no-out-link >/dev/null 2>&1; then
        echo "✓ Build successful"
        return 0
    else
        echo "✗ Build failed - you may need to update npmDepsHash"
        echo "Run: nix-build '<nixpkgs>' -A gemini-cli"
        echo "And update the npmDepsHash in the override file with the suggested hash"
        return 1
    fi
}

# Show current configured version
show_current() {
    if [[ -f "$GEMINI_OVERRIDE_FILE" ]]; then
        local current_version
        current_version=$(grep 'version = ' "$GEMINI_OVERRIDE_FILE" | sed 's/.*version = "\(.*\)";.*/\1/')
        echo "Current configured version: $current_version"
    else
        echo "No override file found - using nixpkgs default"
        nix-instantiate --eval --expr '(import <nixpkgs> {}).gemini-cli.version' | tr -d '"'
    fi
}

# Main function
main() {
    local target="${1:-}"
    
    case "$target" in
        "latest")
            echo "Getting latest release..."
            local latest_version
            latest_version=$(get_latest_version)
            echo "Latest version: $latest_version"
            
            local hash
            hash=$(calculate_version_hash "$latest_version")
            update_override_file "$latest_version" "$hash"
            
            if test_build; then
                echo "Successfully updated to gemini-cli $latest_version"
            fi
            ;;
        "--check-current")
            show_current
            ;;
        "help"|"-h"|"--help"|"")
            usage
            ;;
        *)
            # Check if it looks like a version number
            if [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "Updating to version $target..."
                local hash
                hash=$(calculate_version_hash "$target")
                update_override_file "$target" "$hash"
                
                if test_build; then
                    echo "Successfully updated to gemini-cli $target"
                fi
            # Check if it looks like a git commit
            elif [[ "$target" =~ ^[a-f0-9]{7,40}$ ]]; then
                echo "Updating to git commit $target..."
                local hash
                hash=$(calculate_commit_hash "$target")
                update_override_file "$target" "$hash" "true"
                
                echo "Updated to commit $target"
                echo "Note: You may need to manually update npmDepsHash if build fails"
            else
                echo "Error: Invalid version or commit: $target" >&2
                usage
                exit 1
            fi
            ;;
    esac
}

main "$@"