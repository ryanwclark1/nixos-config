#!/usr/bin/env bash

# Close all windows in Hyprland
# Optionally prompts for confirmation before closing

set -euo pipefail

# Configuration
CONFIRM="${HYPR_CLOSE_CONFIRM:-false}"
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-2000}"

# Notification wrapper
notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t "$NOTIFICATION_TIMEOUT" -u "$urgency" "$title" "$message" 2>/dev/null || true
    fi
}

# Check dependencies
check_dependencies() {
    local missing=()

    if ! command -v hyprctl >/dev/null 2>&1; then
        missing+=("hyprctl")
    fi

    if ! command -v jq >/dev/null 2>&1; then
        missing+=("jq")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies: ${missing[*]}" >&2
        exit 1
    fi
}

# Get all window addresses
get_windows() {
    hyprctl clients -j 2>/dev/null | jq -r '.[].address // empty' 2>/dev/null | grep -v '^$' || echo ""
}

# Confirm action
confirm_action() {
    if [[ "$CONFIRM" != "true" && "$CONFIRM" != "1" ]]; then
        return 0
    fi

    local window_count="$1"
    local message="Close all $window_count windows?"

    if command -v rofi >/dev/null 2>&1; then
        local response
        response=$(echo -e "Yes\nNo" | rofi -dmenu -i -p "$message" 2>/dev/null || echo "No")
        [[ "$response" == "Yes" ]]
    elif command -v wmenu >/dev/null 2>&1; then
        local response
        response=$(echo -e "Yes\nNo" | wmenu -p "$message" 2>/dev/null || echo "No")
        [[ "$response" == "Yes" ]]
    else
        # Fallback: read from stdin
        echo -n "$message (y/N): " >&2
        read -r response
        [[ "$response" =~ ^[Yy]$ ]]
    fi
}

# Close all windows
close_windows() {
    local windows="$1"
    local count=0
    local failed=0

    while IFS= read -r address; do
        if [[ -n "$address" ]]; then
            if hyprctl dispatch closewindow "address:$address" &>/dev/null; then
                ((count++)) || true
            else
                ((failed++)) || true
            fi
        fi
    done <<< "$windows"

    echo "$count"
    return $failed
}

# Main function
main() {
    check_dependencies

    local windows
    windows=$(get_windows)

    if [[ -z "$windows" ]]; then
        notify "Close All Windows" "No windows to close" "normal"
        exit 0
    fi

    local window_count
    window_count=$(echo "$windows" | grep -c . || echo "0")

    if [[ "$window_count" -eq 0 ]]; then
        notify "Close All Windows" "No windows to close" "normal"
        exit 0
    fi

    # Confirm if requested
    if ! confirm_action "$window_count"; then
        notify "Close All Windows" "Cancelled" "normal"
        exit 0
    fi

    # Close windows
    local closed_count
    closed_count=$(close_windows "$windows")

    if [[ "$closed_count" -eq "$window_count" ]]; then
        notify "Close All Windows" "Closed $closed_count windows" "normal"
    elif [[ "$closed_count" -gt 0 ]]; then
        notify "Close All Windows" "Closed $closed_count of $window_count windows" "normal"
    else
        notify "Close All Windows" "Failed to close windows" "critical"
        exit 1
    fi
}

main "$@"
