#!/usr/bin/env bash
#  _   _                      _               _
# | | | |_   _ _ __  _ __ ___| |__   __ _  __| | ___
# | |_| | | | | '_ \| '__/ __| '_ \ / _` |/ _` |/ _ \
# |  _  | |_| | |_) | |  \__ \ | | | (_| | (_| |  __/
# |_| |_|\__, | .__/|_|  |___/_| |_|\__,_|\__,_|\___|
#        |___/|_|
#

set -euo pipefail

# Configuration
SETTINGS_DIR="$HOME/.config/desktop/window-managers/hyprland/scripts/settings"
SETTINGS_FILE="$SETTINGS_DIR/hyprshade.sh"
ROFI_CONFIG="$HOME/.config/rofi/config-hyprshade.rasi"
DEFAULT_FILTER="blue-light-filter-50"

# Check required commands
if ! command -v hyprshade >/dev/null 2>&1; then
    echo "Error: hyprshade not found" >&2
    exit 1
fi

# Notification helper
notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$@"
    fi
}

# Ensure settings directory exists
mkdir -p "$SETTINGS_DIR"

# Rofi selection mode
rofi_mode() {
    if ! command -v rofi >/dev/null 2>&1; then
        echo "Error: rofi not found" >&2
        exit 1
    fi

    # Get available filters
    local options
    options=$(hyprshade ls 2>/dev/null || echo "")
    if [[ -z "$options" ]]; then
        echo "Error: No hyprshade filters available" >&2
        exit 1
    fi
    options="${options}\noff"

    # Open rofi
    local rofi_args=(-dmenu -replace -i -no-show-icons -l 4 -width 30 -p "Hyprshade")
    if [[ -f "$ROFI_CONFIG" ]]; then
        rofi_args+=(-config "$ROFI_CONFIG")
    fi

    local choice
    choice=$(echo -e "$options" | rofi "${rofi_args[@]}" 2>/dev/null || echo "")

    if [[ -n "$choice" ]]; then
        # Save selection
        echo "hyprshade_filter=\"$choice\"" > "$SETTINGS_FILE"

        if [[ "$choice" == "off" ]]; then
            hyprshade off 2>/dev/null || true
            notify "Hyprshade deactivated"
            echo ":: hyprshade turned off"
        else
            notify "Changing Hyprshade to $choice" "Toggle shader with SUPER+SHIFT+S"
        fi
    fi
}

# Toggle mode
toggle_mode() {
    local hyprshade_filter="$DEFAULT_FILTER"

    # Load saved filter if exists
    if [[ -f "$SETTINGS_FILE" ]]; then
        # Source the settings file safely
        # shellcheck source=/dev/null
        source "$SETTINGS_FILE"
    fi

    # Toggle Hyprshade
    if [[ "$hyprshade_filter" != "off" ]]; then
        local current
        current=$(hyprshade current 2>/dev/null || echo "")

        if [[ -z "$current" ]]; then
            echo ":: hyprshade is not running"
            if hyprshade on "$hyprshade_filter" >/dev/null 2>&1; then
                current=$(hyprshade current 2>/dev/null || echo "")
                notify "Hyprshade activated" "with $current"
                echo ":: hyprshade started with $current"
            else
                echo "Error: Failed to start hyprshade" >&2
                exit 1
            fi
        else
            notify "Hyprshade deactivated"
            echo ":: Current hyprshade $current"
            echo ":: Switching hyprshade off"
            hyprshade off 2>/dev/null || true
        fi
    else
        hyprshade off 2>/dev/null || true
        echo ":: hyprshade turned off"
    fi
}

# Main logic
case "${1:-}" in
    "rofi")
        rofi_mode
        ;;
    "")
        toggle_mode
        ;;
    *)
        echo "Usage: $0 [rofi]" >&2
        exit 1
        ;;
esac
