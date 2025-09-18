#!/usr/bin/env bash
# UTC time script for tmux-forceline v2.0
# Displays current UTC time

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/datetime_helpers.sh"

# Get tmux option or use default
get_tmux_option() {
    local option="$1"
    local default="$2"
    tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
}

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