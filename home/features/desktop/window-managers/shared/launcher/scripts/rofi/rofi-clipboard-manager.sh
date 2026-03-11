#!/usr/bin/env bash

# -----------------------------------------------------
# Rofi Clipboard Manager UI Script
# Rofi interface for clipboard history management
# -----------------------------------------------------
#
# This script provides a rofi-based UI for clipboard history management.
# It uses the core clipboard-manager.sh script for functionality.
#
# See clipboard-manager.sh for core functionality
# -----------------------------------------------------

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
DEFAULT_THEME="config"

# Find and source shared utilities
ROFI_HELPERS=""
if [[ -f "$HOME/.local/bin/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$HOME/.local/bin/scripts/system/os-rofi-helpers.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh"
fi

if [[ -n "$ROFI_HELPERS" ]]; then
    # shellcheck source=/dev/null
    source "$ROFI_HELPERS"
fi

# Find core clipboard manager script
# Check deployed locations first (production), then source locations (development)
CORE_SCRIPT=""
if [[ -f "$HOME/.local/bin/scripts/wayland/clipboard-manager.sh" ]]; then
    # Deployed location (production)
    CORE_SCRIPT="$HOME/.local/bin/scripts/wayland/clipboard-manager.sh"
elif command -v clipboard-manager.sh >/dev/null 2>&1; then
    # In PATH
    CORE_SCRIPT="$(command -v clipboard-manager.sh)"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/wayland/clipboard-manager.sh" ]]; then
    # Source location (development)
    CORE_SCRIPT="$SCRIPT_DIR/../../../../common/scripts/wayland/clipboard-manager.sh"
else
    echo "Error: Could not find clipboard-manager.sh core script" >&2
    echo "  Checked: $HOME/.local/bin/scripts/wayland/clipboard-manager.sh" >&2
    echo "  Checked: clipboard-manager.sh in PATH" >&2
    echo "  Checked: $SCRIPT_DIR/../../../../common/scripts/wayland/clipboard-manager.sh" >&2
    exit 1
fi

# Source core script functions
# shellcheck source=/dev/null
source "$CORE_SCRIPT"

# Dependency check function
check_dependencies() {
    local missing_deps=()

    # Check core dependencies via core script
    if ! check_core_dependencies; then
        exit 1
    fi

    # Check rofi using shared helper if available
    if command -v check_rofi >/dev/null 2>&1; then
        if ! check_rofi; then
            exit 1
        fi
    else
        # Fallback check
        command -v rofi >/dev/null || missing_deps+=("rofi")
        if [[ ${#missing_deps[@]} -gt 0 ]]; then
            echo "Error: Missing required dependencies:" >&2
            printf "  - %s\n" "${missing_deps[@]}" >&2
            echo "Please install the missing packages and try again." >&2
            exit 1
        fi
    fi
}

# Get rofi theme path (with cliphist-specific override)
get_rofi_theme_cliphist() {
    # Check for specific cliphist theme first
    local cliphist_theme="$CONFIG_DIR/cliphist.rasi"
    if [[ -f "$cliphist_theme" ]]; then
        echo "$cliphist_theme"
        return
    fi

    # Use shared helper if available
    if command -v get_rofi_theme >/dev/null 2>&1; then
        get_rofi_theme "$DEFAULT_THEME"
    else
        # Fallback implementation
        local theme_path="$CONFIG_DIR/$DEFAULT_THEME.rasi"
        if [[ -f "$theme_path" ]]; then
            echo "$theme_path"
        else
            echo ""
        fi
    fi
}

# Run rofi with theme
run_rofi() {
    local prompt="$1"
    local message="${2:-}"
    local additional_args=("${@:3}")
    local theme_path
    theme_path=$(get_rofi_theme_cliphist)

    local rofi_args=(
        -dmenu
        -p "$prompt"
        -i  # Case insensitive
        -format "s"  # Return selection
        -display-columns "1"
    )

    # Add message if provided
    [[ -n "$message" ]] && rofi_args+=(-mesg "$message")

    # Add theme if available
    [[ -n "$theme_path" ]] && rofi_args+=(-theme "$theme_path")

    # Add any additional arguments
    rofi_args+=("${additional_args[@]}")

    rofi "${rofi_args[@]}"
}

# Rofi selector function for use with core script
rofi_select_item() {
    local prompt="$1"
    local message="$2"
    run_rofi "$prompt" "$message" -replace
}

# Rofi confirm function for use with core script
rofi_confirm() {
    local prompt="$1"
    local message="$2"
    run_rofi "$prompt" "$message"
}

# Show clipboard history and select item
show_clipboard_history() {
    show_clipboard_history_ui rofi_select_item
}

# Delete specific clipboard entries
delete_clipboard_entries() {
    delete_clipboard_entries_ui rofi_select_item rofi_confirm
}

# Clear all clipboard history
clear_clipboard_history() {
    clear_clipboard_history_ui rofi_confirm
}

# Show usage information
usage() {
    cat << EOF
Rofi Clipboard Manager UI Script

Usage: $0 [COMMAND]

Commands:
    show         Show clipboard history and select item (default)
    delete       Delete specific clipboard entries
    clear        Clear all clipboard history
    help         Show this help

Keyboard shortcuts (when running):
    Enter        Copy selected item
    Delete       Delete selected item (in delete mode)
    Escape       Cancel/exit

Configuration:
    Theme: ~/.config/rofi/cliphist.rasi (fallback to config.rasi)
    Database: ~/.cache/cliphist/db

Examples:
    $0                    # Show clipboard history
    $0 show               # Same as above
    $0 delete             # Delete specific entries
    $0 clear              # Clear all history

Dependencies:
    - cliphist
    - rofi
    - wl-clipboard (wl-copy, wl-paste)
EOF
}

# Main function
main() {
    local command="${1:-show}"

    # Handle help first (no dependency check needed)
    if [[ "$command" == "help" || "$command" == "-h" || "$command" == "--help" ]]; then
        usage
        exit 0
    fi

    # Check all dependencies for UI commands
    check_dependencies

    case "$command" in
        "show"|"")
            show_clipboard_history
            ;;
        "delete"|"d")
            delete_clipboard_entries
            ;;
        "clear"|"wipe"|"w")
            clear_clipboard_history
            ;;
        *)
            echo "Error: Unknown command '$command'" >&2
            echo "Use '$0 help' for usage information" >&2
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
