#!/usr/bin/env bash

# -----------------------------------------------------
# Rofi Helper Utilities
# Shared rofi configuration and theme utilities
# -----------------------------------------------------
#
# This script provides shared utilities for rofi-based scripts,
# including theme detection, common rofi arguments, and helper functions.
# -----------------------------------------------------

set -euo pipefail

# Configuration
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
DEFAULT_THEME="config"

# Get rofi theme path
get_rofi_theme() {
    local theme_name="${1:-$DEFAULT_THEME}"
    local theme_path="$CONFIG_DIR/$theme_name.rasi"

    # Check if theme exists
    if [[ -f "$theme_path" ]]; then
        echo "$theme_path"
    else
        # Return empty string to use default theme
        echo ""
    fi
}

# Get rofi theme layout (icon-only vs text mode)
get_rofi_theme_layout() {
    local theme_path="${1:-}"

    if [[ -z "$theme_path" ]]; then
        theme_path=$(get_rofi_theme)
    fi

    if [[ -n "$theme_path" && -f "$theme_path" ]]; then
        local layout
        layout=$(grep 'USE_ICON' "$theme_path" 2>/dev/null | cut -d'=' -f2 | tr -d ' "'"'" || echo "YES")
        echo "$layout"
    else
        echo "YES"  # Default to icon mode
    fi
}

# Get rofi theme grid configuration
get_rofi_theme_grid() {
    local theme_path="${1:-}"

    if [[ -z "$theme_path" ]]; then
        theme_path=$(get_rofi_theme)
    fi

    if [[ -z "$theme_path" ]]; then
        echo "1 6 400px"  # Default: 1 column, 6 rows, 400px width
        return
    fi

    local theme_name
    theme_name=$(basename "$theme_path" .rasi)

    # Determine grid based on theme type
    if [[ "$theme_name" == *"type-1"* ]] || [[ "$theme_name" == *"type-3"* ]] || [[ "$theme_name" == *"type-5"* ]]; then
        echo "1 6 400px"
    elif [[ "$theme_name" == *"type-2"* ]] || [[ "$theme_name" == *"type-4"* ]]; then
        echo "6 1 720px"
    else
        echo "1 6 400px"  # Default
    fi
}

# Build common rofi arguments
build_rofi_args() {
    local prompt="$1"
    local message="${2:-}"
    local theme_name="${3:-}"
    local additional_args=("${@:4}")

    local theme_path
    if [[ -n "$theme_name" ]]; then
        theme_path=$(get_rofi_theme "$theme_name")
    else
        theme_path=$(get_rofi_theme)
    fi

    local rofi_args=(
        -dmenu
        -p "$prompt"
        -i  # Case insensitive
    )

    # Add message if provided
    [[ -n "$message" ]] && rofi_args+=(-mesg "$message")

    # Add theme if available
    [[ -n "$theme_path" ]] && rofi_args+=(-theme "$theme_path")

    # Add any additional arguments
    rofi_args+=("${additional_args[@]}")

    # Return as string (caller should use eval or array expansion)
    printf '%s\n' "${rofi_args[@]}"
}

# Check if rofi is available
check_rofi() {
    if ! command -v rofi >/dev/null 2>&1; then
        echo "Error: rofi not found" >&2
        echo "Please install rofi to use this script" >&2
        return 1
    fi
    return 0
}
