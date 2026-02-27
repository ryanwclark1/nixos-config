#!/usr/bin/env bash

# Increase audio volume by 5%
# Dependencies: wpctl, notify-send

set -euo pipefail

# Configuration
PATH="/run/current-system/sw/bin:/usr/bin:$PATH"
VOLUME_STEP="${AUDIO_VOLUME_STEP:-5}"
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

# Get current volume
get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "Volume: 0%"
}

# Increase volume
increase_volume() {
    local step="${1:-$VOLUME_STEP}"

    if wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}%+" &>/dev/null; then
        local volume
        volume=$(get_volume)
        notify "Volume" "$volume" "low"
        return 0
    else
        notify "Volume" "Failed to increase volume" "critical"
        echo "Error: Failed to increase volume" >&2
        return 1
    fi
}

# Usage information
usage() {
    cat << EOF
Audio Volume Up

Usage: $0 [STEP]

Arguments:
    STEP    Volume step percentage (default: 5)

Environment Variables:
    AUDIO_VOLUME_STEP          Volume step percentage (default: 5)
    HYPR_NOTIFICATION_TIMEOUT  Notification duration (default: 1000ms)

Examples:
    $0        # Increase volume by 5%
    $0 10     # Increase volume by 10%
EOF
}

# Main function
main() {
    local step="${1:-$VOLUME_STEP}"

    if [[ "$step" == "-h" || "$step" == "--help" ]]; then
        usage
        exit 0
    fi

    # Validate step
    if ! [[ "$step" =~ ^[0-9]+$ ]] || [[ "$step" -lt 1 || "$step" -gt 100 ]]; then
        echo "Error: Step must be a number between 1-100" >&2
        exit 1
    fi

    check_dependencies
    increase_volume "$step"
}

main "$@"
