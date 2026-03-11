#!/bin/bash

set -euo pipefail

# Returns the battery time remaining (to empty or full) in a compact format.
# Uses shared battery library for robust detection with multiple fallback methods.

# Source the shared battery library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/os-battery-lib.sh" 2>/dev/null || {
    # Fallback to upower if library not available
    BATTERY_DEVICE=$(upower -e 2>/dev/null | grep -E 'BAT' | head -1 || echo "")
    if [[ -z "$BATTERY_DEVICE" ]]; then
        exit 1
    fi
    battery_info=$(upower -i "$BATTERY_DEVICE" 2>/dev/null)
    if [[ -z "$battery_info" ]]; then
        exit 1
    fi
    time_str=$(echo "$battery_info" | awk '/time to (empty|full)/ {
        hours = int($4)
        minutes = int(($4 - hours) * 60)
        if (minutes > 0) {
            printf "%dh %dm", hours, minutes
        } else {
            printf "%dh", hours
        }
        exit
    }' || echo "")
    if [[ -n "$time_str" ]]; then
        echo "$time_str"
    else
        exit 1
    fi
    exit 0
}

# Use shared library function
get_battery_time_remaining || exit 1
