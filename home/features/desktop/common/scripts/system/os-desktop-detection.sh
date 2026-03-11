#!/usr/bin/env bash

# -----------------------------------------------------
# Desktop System Detection Utilities
# Shared utilities for detecting desktop vs laptop systems
# -----------------------------------------------------
#
# This script provides shared utilities for detecting whether
# the system is a desktop (no battery) or laptop (with battery).
# -----------------------------------------------------

set -euo pipefail

# Source battery library if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/os-battery-lib.sh" ]]; then
    # shellcheck source=os-battery-lib.sh
    source "$SCRIPT_DIR/os-battery-lib.sh"
fi

# Check if system has a battery (desktop vs laptop detection)
is_desktop_system() {
    # Use shared battery library if available
    if command -v has_battery >/dev/null 2>&1; then
        if has_battery; then
            return 1  # Has battery = laptop
        else
            return 0  # No battery = desktop
        fi
    fi

    # Fallback: check /sys/class/power_supply
    local bat_path="/sys/class/power_supply"
    if [[ -d "$bat_path" ]]; then
        for bat_dir in "$bat_path"/BAT*; do
            if [[ -d "$bat_dir" && -f "$bat_dir/capacity" ]]; then
                return 1  # Found battery = laptop
            fi
        done
    fi

    # No battery found = desktop
    return 0
}

# Get system type string
get_system_type() {
    if is_desktop_system; then
        echo "desktop"
    else
        echo "laptop"
    fi
}
