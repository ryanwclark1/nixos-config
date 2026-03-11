#!/bin/bash

set -euo pipefail

# Returns the battery state (Charging, Discharging, Full, or Unknown).
# Uses shared battery library for robust detection with multiple fallback methods.

# Source the shared battery library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/os-battery-lib.sh" 2>/dev/null || {
    # Fallback to upower if library not available
    BATTERY_DEVICE=$(upower -e 2>/dev/null | grep -E 'BAT' | head -1 || echo "")
    if [[ -z "$BATTERY_DEVICE" ]]; then
        echo ""
        exit 0
    fi
    upower -i "$BATTERY_DEVICE" 2>/dev/null | grep -E "state" | awk '{print $2}' || echo ""
    exit 0
}

# Use shared library function
get_battery_state || echo ""
