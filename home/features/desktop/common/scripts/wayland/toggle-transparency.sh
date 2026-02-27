#!/usr/bin/env bash

# Toggle window transparency/opacity for the active window

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"

# Logging function
log() {
    echo "[$SCRIPT_NAME] $1" >&2
}

# Notification wrapper
notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t 3000 "$@"
    else
        log "$*"
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=()

    command -v hyprctl >/dev/null 2>&1 || missing_deps+=("hyprctl")
    command -v jq >/dev/null 2>&1 || missing_deps+=("jq")

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "Error: Missing required dependencies: ${missing_deps[*]}"
        notify "Error" "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

# Get active window address
get_active_window_address() {
    local window_json
    window_json=$(hyprctl activewindow -j 2>/dev/null || echo "")

    if [[ -z "$window_json" ]]; then
        log "Error: Could not get active window information"
        return 1
    fi

    local address
    address=$(echo "$window_json" | jq -r '.address // empty' 2>/dev/null || echo "")

    if [[ -z "$address" ]] || [[ "$address" == "null" ]]; then
        log "No active window found"
        return 1
    fi

    echo "$address"
}

# Toggle window transparency
toggle_transparency() {
    local address="$1"

    if ! [[ "$address" =~ ^0x[0-9a-fA-F]+$ ]]; then
        log "Error: Invalid window address format: $address"
        return 1
    fi

    log "Toggling transparency for window: $address"

    if hyprctl dispatch setprop "address:$address" opaque toggle >/dev/null 2>&1; then
        return 0
    else
        log "Error: Failed to toggle transparency"
        return 1
    fi
}

# Main logic
main() {
    check_dependencies

    local address
    address=$(get_active_window_address)

    if [[ -z "$address" ]]; then
        notify "No Active Window" "No window to toggle transparency"
        exit 1
    fi

    if toggle_transparency "$address"; then
        log "Successfully toggled window transparency"
    else
        notify "Error" "Failed to toggle window transparency"
        exit 1
    fi
}

main "$@"
