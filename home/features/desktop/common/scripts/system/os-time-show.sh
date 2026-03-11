#!/usr/bin/env bash

# Show current date and time as notification
# Dependencies: notify-send (optional), date

set -euo pipefail

# Configuration
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-3000}"

# Notification wrapper
notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t "$NOTIFICATION_TIMEOUT" -u "$urgency" "$title" "$message" 2>/dev/null || true
    else
        echo "$title: $message" >&2
    fi
}

# Get current time information
get_time_info() {
    local current_time current_date week_number day_of_year timezone

    # Get time components
    current_time=$(date +"%H:%M:%S" 2>/dev/null || echo "Unknown")
    current_date=$(date +"%A, %B %d, %Y" 2>/dev/null || echo "Unknown")
    week_number=$(date +"%V" 2>/dev/null || echo "Unknown")
    day_of_year=$(date +"%j" 2>/dev/null || echo "Unknown")
    timezone=$(date +"%Z %z" 2>/dev/null || echo "Unknown")

    # Build message
    local message
    message="Time: $current_time
Date: $current_date
Week: $week_number • Day: $day_of_year
Zone: $timezone"

    echo "$message"
}

# Usage information
usage() {
    cat << EOF
Show Current Time

Usage: $0 [OPTIONS]

Options:
    -h, --help    Show this help message

Description:
    Displays current date and time information as a notification.

Environment Variables:
    HYPR_NOTIFICATION_TIMEOUT    Notification duration (default: 3000ms)

Examples:
    $0              # Show current time
EOF
}

# Main function
main() {
    local arg="${1:-}"

    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        usage
        exit 0
    fi

    local message
    message=$(get_time_info)
    notify "🕐 Current Time" "$message" "low"
}

main "$@"
