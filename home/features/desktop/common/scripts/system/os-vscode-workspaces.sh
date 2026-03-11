#!/usr/bin/env bash

# -----------------------------------------------------
# VS Code Workspace Utilities
# Shared utilities for parsing VS Code workspace files
# -----------------------------------------------------
#
# This script provides shared utilities for finding and parsing
# VS Code/Codium workspace files from storage.json and workspaceStorage.
# -----------------------------------------------------

set -euo pipefail

# Expand tilde in paths
expand_tilde() {
    echo "$1" | sed "s|^~|$HOME|"
}

# Contract home directory to tilde
contract_tilde() {
    echo "$1" | sed "s|^$HOME|~|"
}

# Portable function to get file modification time
get_file_mtime() {
    local file="$1"
    # Try GNU stat first (Linux)
    if stat -c %Y "$file" 2>/dev/null; then
        return 0
    fi
    # Try BSD stat (macOS/FreeBSD)
    if stat -f %m "$file" 2>/dev/null; then
        return 0
    fi
    # Fallback: use find (most portable)
    if find "$file" -printf '%T@' 2>/dev/null | head -1; then
        return 0
    fi
    # Last resort: return 0
    echo 0
}

# Parse storage.json and extract workspace paths
get_workspaces_from_storage() {
    local config_dir="$1"
    local fullpath="${2:-false}"
    local storage_file
    storage_file=$(expand_tilde "$config_dir/User/storage.json")

    if [[ ! -f "$storage_file" ]]; then
        return
    fi

    # Extract workspace paths from storage.json using jq
    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    jq -r '.openedPathsList.workspaces3[]' "$storage_file" 2>/dev/null | while read -r j; do
        if [[ "$j" == file://* ]]; then
            local folder="${j:7}"
            # Validate folder exists
            if [[ ! -d "$folder" ]]; then
                continue
            fi
            local basename
            basename=$(basename "$folder")
            [[ "$fullpath" == "false" ]] && folder=$(contract_tilde "$folder")
            echo "$folder|$basename|$(get_file_mtime "$folder")"
        fi
    done
}

# Parse workspaceStorage directories
get_workspaces_from_user_workspace() {
    local config_dir="$1"
    local fullpath="${2:-false}"
    local workspace_dirs
    workspace_dirs=$(find "$(expand_tilde "$config_dir")/User/workspaceStorage" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    for dir in $workspace_dirs; do
        local ws_file="$dir/workspace.json"
        if [[ -f "$ws_file" ]]; then
            local folder
            folder=$(jq -r '.folder' "$ws_file" 2>/dev/null)
            if [[ "$folder" == file://* ]]; then
                folder="${folder:7}"
                # Validate folder exists
                if [[ ! -d "$folder" ]]; then
                    continue
                fi
                local basename
                basename=$(basename "$folder")
                local time
                time=$(get_file_mtime "$dir/state.vscdb")
                [[ "$fullpath" == "false" ]] && folder=$(contract_tilde "$folder")
                echo "$folder|$basename|$time"
            fi
        fi
    done
}

# Get all workspaces from multiple config paths
get_all_workspaces() {
    local config_paths="$1"
    local fullpath="${2:-false}"
    local workspaces=""

    IFS=',' read -ra BASE_PATHS <<< "$config_paths"

    for base_path in "${BASE_PATHS[@]}"; do
        workspaces+="$(get_workspaces_from_user_workspace "$base_path" "$fullpath")"$'\n'
        workspaces+="$(get_workspaces_from_storage "$base_path" "$fullpath")"$'\n'
    done

    # Remove empty lines and duplicates
    echo "$workspaces" | grep -v '^$' | awk -F'|' '!seen[$2]++'
}

# Sort workspaces
sort_workspaces() {
    local sort_type="$1"
    case "$sort_type" in
        "name") sort -t'|' -k2 ;;
        "path") sort -t'|' -k1 ;;
        "time") sort -t'|' -k3,3nr ;;
        *) echo "Invalid sort option!" >&2; exit 1 ;;
    esac
}

# Detect VS Code or Codium binary
detect_code_editor() {
    for binary in "codium" "code"; do
        if command -v "$binary" >/dev/null 2>&1; then
            echo "$binary"
            return 0
        fi
    done
    echo ""
    return 1
}
