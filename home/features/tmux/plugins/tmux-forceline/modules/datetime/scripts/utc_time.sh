#!/usr/bin/env bash
# UTC time script for tmux-forceline v3.0
# Displays current UTC time

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/datetime/scripts/datetime_helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/datetime_helpers.sh"
fi

# Main UTC time function
main() {
    # Get configuration from tmux options
    local time_format
    
    time_format=$(get_tmux_option "@forceline_datetime_utc_format" "%H:%M UTC")
    
    # Get and display UTC time
    get_utc_time "$time_format"
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi