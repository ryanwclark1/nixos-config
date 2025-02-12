#!/usr/bin/env bash

CONFIG_PATHS="$HOME/.config/VSCodium,$HOME/.config/Code,$HOME/.config/Code - OSS"
SORT_OPTION="time"
FULLPATH=false
OUTPUT=false
INSENSITIVE=false
ROFI_CMD="rofi -dmenu -p 'Open workspace' -no-custom"
CODE_CMD=""

# Function to detect VS Code or Codium
detect_code_editor() {
    for binary in "codium" "code"; do
        if command -v "$binary" >/dev/null 2>&1; then
            CODE_CMD="$binary"
            return
        fi
    done
    echo "No Code or Codium found. Use --code option to specify." >&2
    exit 1
}

# Function to expand tilde in paths
expand_tilde() {
    echo "$1" | sed "s|^~|$HOME|"
}

# Function to contract home directory to tilde
contract_tilde() {
    echo "$1" | sed "s|^$HOME|~|"
}

# Function to parse storage.json and extract workspace paths
get_workspaces_from_storage() {
    local config_dir="$1"
    local storage_file
    storage_file=$(expand_tilde "$config_dir/User/storage.json")

    if [[ ! -f "$storage_file" ]]; then
        return
    fi

    # Extract workspace paths from storage.json using jq
    jq -r '.openedPathsList.workspaces3[]' "$storage_file" 2>/dev/null | while read -r j; do
        if [[ "$j" == file://* ]]; then
            local folder="${j:7}"
            local basename
            basename=$(basename "$folder")
            [[ "$FULLPATH" == "false" ]] && folder=$(contract_tilde "$folder")
            echo "$folder|$basename|$(stat -c %Y "$folder" 2>/dev/null || echo 0)"
        fi
    done
}

# Function to parse workspaceStorage directories
get_workspaces_from_user_workspace() {
    local config_dir="$1"
    local workspace_dirs
    workspace_dirs=$(find "$(expand_tilde "$config_dir")/User/workspaceStorage" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

    for dir in $workspace_dirs; do
        local ws_file="$dir/workspace.json"
        if [[ -f "$ws_file" ]]; then
            local folder
            folder=$(jq -r '.folder' "$ws_file" 2>/dev/null)
            if [[ "$folder" == file://* ]]; then
                folder="${folder:7}"
                local basename
                basename=$(basename "$folder")
                local time
                time=$(stat -c %Y "$dir/state.vscdb" 2>/dev/null || echo 0)
                [[ "$FULLPATH" == "false" ]] && folder=$(contract_tilde "$folder")
                echo "$folder|$basename|$time"
            fi
        fi
    done
}

# Function to sort workspaces
sort_workspaces() {
    local sort_type="$1"
    case "$sort_type" in
        "name") sort -t'|' -k2 ;;
        "path") sort -t'|' -k1 ;;
        "time") sort -t'|' -k3,3nr ;;
        *) echo "Invalid sort option!" >&2; exit 1 ;;
    esac
}

# Function to remove duplicates
unique_workspaces() {
    awk -F'|' '!seen[$2]++'
}

# Function to run rofi
run_rofi() {
    local workspaces="$1"
    local selected
    selected=$(echo "$workspaces" | cut -d'|' -f1 | $ROFI_CMD)

    [[ -z "$selected" ]] && exit 0

    selected=$(expand_tilde "$selected")
    $CODE_CMD "$selected" &
}

# Argument parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir) CONFIG_PATHS="$2"; shift ;;
        -s|--sort) SORT_OPTION="$2"; shift ;;
        -f|--full) FULLPATH=true ;;
        -o|--output) OUTPUT=true ;;
        -i|--insensitive) INSENSITIVE=true ;;
        -r|--rofi) ROFI_CMD="$2"; shift ;;
        -c|--code) CODE_CMD="$2"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Detect Code/Codium if not specified
[[ -z "$CODE_CMD" ]] && detect_code_editor

# Case-insensitive search option for rofi
[[ "$INSENSITIVE" == "true" ]] && ROFI_CMD+=" -i"

IFS=',' read -ra BASE_PATHS <<< "$CONFIG_PATHS"
WORKSPACES=""

for base_path in "${BASE_PATHS[@]}"; do
    WORKSPACES+="$(get_workspaces_from_user_workspace "$base_path")"$'\n'
    WORKSPACES+="$(get_workspaces_from_storage "$base_path")"$'\n'
done

# Remove empty lines and duplicate workspaces
WORKSPACES=$(echo "$WORKSPACES" | grep -v '^$' | unique_workspaces)

if [[ -z "$WORKSPACES" ]]; then
    echo "No workspaces found." >&2
    exit 1
fi

# Sort workspaces
WORKSPACES=$(echo "$WORKSPACES" | sort_workspaces "$SORT_OPTION")

# Output or launch rofi
if [[ "$OUTPUT" == "true" ]]; then
    echo "$WORKSPACES" | cut -d'|' -f1
else
    run_rofi "$WORKSPACES"
fi
