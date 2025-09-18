#!/usr/bin/env bash
# Time script for tmux-forceline v2.0
# Enhanced time display with timezone and locale support

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/datetime_helpers.sh"

# Get tmux option or use default
get_tmux_option() {
    local option="$1"
    local default="$2"
    tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
}

# Main time function
main() {
    # Get configuration from tmux options
    local time_format
    local timezone
    local locale
    
    time_format=$(get_tmux_option "@forceline_datetime_time_format" "%H:%M")
    timezone=$(get_tmux_option "@forceline_datetime_timezone" "")
    locale=$(get_tmux_option "@forceline_datetime_locale" "")
    
    # Set environment variables for helpers
    export FORCELINE_DATETIME_TIME_FORMAT="$time_format"
    export FORCELINE_DATETIME_TIMEZONE="$timezone"
    export FORCELINE_DATETIME_LOCALE="$locale"
    
    # Get and display the time
    get_time "$time_format" "$timezone"
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi