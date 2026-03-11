#!/bin/bash

set -euo pipefail

# Returns a formatted battery status string with percentage and power draw/charge.
# Uses shared battery library for robust detection with multiple fallback methods.

# Source the shared battery library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/os-battery-lib.sh" 2>/dev/null || {
    echo "󰚥    Battery library not available" >&2
    exit 1
}

# Check if battery is present
if ! has_battery 2>/dev/null; then
    echo "󰚥    No battery detected"
    exit 0
fi

# Get battery information
percentage=$(get_battery_percentage || echo "")
state=$(get_battery_state || echo "")
power_rate=$(get_battery_power_rate 2>/dev/null || echo "")
time_remaining=$(get_battery_time_remaining 2>/dev/null || echo "calculating...")
capacity=$(get_battery_capacity 2>/dev/null || echo "?")

# Validate we have at least percentage
if [[ -z "$percentage" ]]; then
    echo "󰚥    Battery information unavailable"
    exit 1
fi

# Format output based on state
if [[ "$state" == "Charging" ]]; then
    echo "󰁹    Battery ${percentage}%  ·  ${time_remaining} to full  ·   ${power_rate}W / ${capacity}Wh"
else
    echo "󰁹    Battery ${percentage}%  ·  ${time_remaining} left  ·   ${power_rate}W / ${capacity}Wh"
fi
