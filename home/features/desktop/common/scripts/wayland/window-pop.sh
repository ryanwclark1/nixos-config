#!/usr/bin/env bash

# Pop window out - make it floating and pinned (always on top across workspaces)

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

# Get active window information
get_active_window_info() {
    local window_json
    window_json=$(hyprctl activewindow -j 2>/dev/null || echo "")

    if [[ -z "$window_json" ]]; then
        log "Error: Could not get active window information"
        return 1
    fi

    local address
    address=$(echo "$window_json" | jq -r '.address // empty' 2>/dev/null || echo "")
    local floating
    floating=$(echo "$window_json" | jq -r '.floating // "false"' 2>/dev/null || echo "false")

    if [[ -z "$address" ]] || [[ "$address" == "null" ]]; then
        log "No active window found"
        return 1
    fi

    echo "$address|$floating"
}

# Make window floating
make_floating() {
    log "Making window floating"

    if hyprctl dispatch togglefloating >/dev/null 2>&1; then
        sleep 0.1  # Give it time to apply
        return 0
    else
        log "Error: Failed to toggle floating"
        return 1
    fi
}

# Pin the window
pin_window() {
    log "Pinning window"

    if hyprctl dispatch pin >/dev/null 2>&1; then
        return 0
    else
        log "Error: Failed to pin window"
        return 1
    fi
}

# Main logic
main() {
    check_dependencies

    local window_info
    window_info=$(get_active_window_info)

    if [[ -z "$window_info" ]]; then
        notify "No Active Window" "No window to pop out"
        exit 1
    fi

    IFS='|' read -r address floating <<< "$window_info"
    log "Active window: $address (floating: $floating)"

    # Make window floating if it isn't already
    if [[ "$floating" == "false" ]]; then
        if ! make_floating; then
            notify "Error" "Failed to make window floating"
            exit 1
        fi
    fi

    # Pin the window
    if pin_window; then
        notify "Window Pinned" "Window will stay visible across all workspaces"
        log "Successfully popped out window"
    else
        notify "Error" "Failed to pin window"
        exit 1
    fi
}

main "$@"
