#!/bin/bash

set -euo pipefail

# Returns the battery full capacity in Wh (rounded to whole number).
# Uses shared battery library for robust detection with multiple fallback methods.

# Source the shared battery library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/os-battery-lib.sh" 2>/dev/null || {
    # Fallback to upower if library not available
    BATTERY_DEVICE=$(upower -e 2>/dev/null | grep -E 'BAT' | head -1 || echo "")
    if [[ -z "$BATTERY_DEVICE" ]]; then
        exit 1
    fi
    capacity=$(upower -i "$BATTERY_DEVICE" 2>/dev/null | awk '/energy-full:/ {
        printf "%d", $2
        exit
    }' || echo "")
    if [[ -n "$capacity" && "$capacity" =~ ^[0-9]+$ ]]; then
        echo "$capacity"
    else
        exit 1
    fi
    exit 0
}

# Use shared library function
get_battery_capacity || exit 1
