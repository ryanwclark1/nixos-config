#!/bin/bash

set -euo pipefail

# Returns the battery device identifier.
# Uses shared battery library for robust detection with multiple fallback methods.

# Source the shared battery library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/os-battery-lib.sh" 2>/dev/null || {
    # Fallback to upower if library not available
    upower -e 2>/dev/null | grep -E 'BAT' | head -1 || echo ""
    exit 0
}

# Use shared library function
get_battery_device || echo ""
