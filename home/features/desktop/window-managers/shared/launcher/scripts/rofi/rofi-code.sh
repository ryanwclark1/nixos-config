#!/usr/bin/env bash
set -euo pipefail

# Find and source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VSCODE_WORKSPACES=""
ROFI_HELPERS=""

if [[ -f "$HOME/.local/bin/scripts/system/os-vscode-workspaces.sh" ]]; then
    VSCODE_WORKSPACES="$HOME/.local/bin/scripts/system/os-vscode-workspaces.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-vscode-workspaces.sh" ]]; then
    VSCODE_WORKSPACES="$SCRIPT_DIR/../../../../common/scripts/system/os-vscode-workspaces.sh"
fi

if [[ -f "$HOME/.local/bin/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$HOME/.local/bin/scripts/system/os-rofi-helpers.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh"
fi

if [[ -n "$VSCODE_WORKSPACES" ]]; then
    # shellcheck source=/dev/null
    source "$VSCODE_WORKSPACES"
fi

if [[ -n "$ROFI_HELPERS" ]]; then
    # shellcheck source=/dev/null
    source "$ROFI_HELPERS"
fi

CONFIG_PATHS="$HOME/.config/VSCodium,$HOME/.config/Code,$HOME/.config/Code - OSS"
SORT_OPTION="time"
FULLPATH=false
OUTPUT=false
INSENSITIVE=false
ROFI_STYLE="$HOME/.config/rofi/style/config-code.rasi"
ROFI_CMD="rofi -dmenu -p 'Open workspace' -no-custom -theme $ROFI_STYLE"
CODE_CMD=""

# Function to detect VS Code or Codium using shared function if available
detect_code_editor() {
    if command -v detect_code_editor >/dev/null 2>&1; then
        CODE_CMD=$(detect_code_editor)
        if [[ -z "$CODE_CMD" ]]; then
            echo "No Code or Codium found. Use --code option to specify." >&2
            exit 1
        fi
    else
        # Fallback implementation
        for binary in "codium" "code"; do
            if command -v "$binary" >/dev/null 2>&1; then
                CODE_CMD="$binary"
                return
            fi
        done
        echo "No Code or Codium found. Use --code option to specify." >&2
        exit 1
    fi
}

# Use shared functions if available, otherwise define fallbacks
if ! command -v expand_tilde >/dev/null 2>&1; then
    expand_tilde() {
        echo "$1" | sed "s|^~|$HOME|"
    }
fi

if ! command -v sort_workspaces >/dev/null 2>&1; then
    sort_workspaces() {
        local sort_type="$1"
        case "$sort_type" in
            "name") sort -t'|' -k2 ;;
            "path") sort -t'|' -k1 ;;
            "time") sort -t'|' -k3,3nr ;;
            *) echo "Invalid sort option!" >&2; exit 1 ;;
        esac
    }
fi

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

    # Validate workspace path exists before opening
    if [[ ! -d "$selected" ]]; then
        notify-send "Error" "Workspace not found: $selected" 2>/dev/null || \
            echo "Error: Workspace not found: $selected" >&2
        exit 1
    fi

    if ! command -v "$CODE_CMD" >/dev/null 2>&1; then
        notify-send "Error" "Code editor not found: $CODE_CMD" 2>/dev/null || \
            echo "Error: Code editor not found: $CODE_CMD" >&2
        exit 1
    fi

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

# Get workspaces using shared function if available
if command -v get_all_workspaces >/dev/null 2>&1; then
    WORKSPACES=$(get_all_workspaces "$CONFIG_PATHS" "$FULLPATH")
else
    # Fallback: manual parsing
    IFS=',' read -ra BASE_PATHS <<< "$CONFIG_PATHS"
    WORKSPACES=""

    for base_path in "${BASE_PATHS[@]}"; do
        if command -v get_workspaces_from_user_workspace >/dev/null 2>&1; then
            WORKSPACES+="$(get_workspaces_from_user_workspace "$base_path" "$FULLPATH")"$'\n'
        fi
        if command -v get_workspaces_from_storage >/dev/null 2>&1; then
            WORKSPACES+="$(get_workspaces_from_storage "$base_path" "$FULLPATH")"$'\n'
        fi
    done

    # Remove empty lines and duplicate workspaces
    WORKSPACES=$(echo "$WORKSPACES" | grep -v '^$' | unique_workspaces)
fi

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
