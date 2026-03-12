#!/usr/bin/env bash
# Battery Status Script for tmux-forceline
# Returns the current battery status (charging, discharging, etc.)

# Source shared utilities + battery-specific helpers
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../utils" && pwd)"
source "$UTILS_DIR/source_helpers.sh"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/battery_helpers.sh"

main() {
    battery_status
}

main