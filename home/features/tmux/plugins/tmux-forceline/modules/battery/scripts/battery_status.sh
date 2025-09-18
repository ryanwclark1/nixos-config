#!/usr/bin/env bash
# Battery Status Script for tmux-forceline
# Returns the current battery status (charging, discharging, etc.)

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

main() {
    battery_status
}

main