#!/usr/bin/env bash

# -----------------------------------------------------
# Notification Library
# Shared notification wrapper for system scripts
# -----------------------------------------------------
# Source this file to get a standardized notify() function.
# Respects HYPR_NOTIFICATION_TIMEOUT for duration.
# -----------------------------------------------------

# Default notification timeout (ms)
NOTIFICATION_TIMEOUT="${HYPR_NOTIFICATION_TIMEOUT:-3000}"

# Notification wrapper
# Usage: notify "Title" "Message" [urgency]
# urgency: low, normal (default), critical
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
