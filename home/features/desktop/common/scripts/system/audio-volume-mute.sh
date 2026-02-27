#!/usr/bin/env bash

# Toggle audio mute state
# Dependencies: wpctl, notify-send

set -euo pipefail

# Configuration
PATH="/run/current-system/sw/bin:/usr/bin:$PATH"
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-1000}"

# Check dependencies
check_dependencies() {
    if ! command -v wpctl >/dev/null 2>&1; then
        echo "Error: wpctl not found. Please install wireplumber or pipewire-wireplumber" >&2
        exit 1
    fi
}

# Notification wrapper
notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t "$NOTIFICATION_TIMEOUT" -u "$urgency" "$title" "$message" 2>/dev/null || true
    fi
}

# Check if audio is muted
is_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED" || return 1
}

# Toggle mute
toggle_mute() {
    if wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle &>/dev/null; then
        if is_muted; then
            notify "󰝟 Audio" "Muted" "normal"
        else
            notify " Audio" "Unmuted" "normal"
        fi
        return 0
    else
        notify "Audio" "Failed to toggle mute" "critical"
        echo "Error: Failed to toggle mute" >&2
        return 1
    fi
}

# Usage information
usage() {
    cat << EOF
Audio Mute Toggle

Usage: $0 [OPTIONS]

Options:
    -h, --help    Show this help message

Description:
    Toggles the mute state of the default audio sink.

Environment Variables:
    HYPR_NOTIFICATION_TIMEOUT  Notification duration (default: 1000ms)

Examples:
    $0              # Toggle mute state
EOF
}

# Main function
main() {
    local arg="${1:-}"

    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        usage
        exit 0
    fi

    check_dependencies
    toggle_mute
}

main "$@"
