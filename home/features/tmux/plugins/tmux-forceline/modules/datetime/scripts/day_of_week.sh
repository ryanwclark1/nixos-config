#!/usr/bin/env bash
# Day of week script for tmux-forceline v2.0
# Displays current day of week with format options

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/datetime_helpers.sh"

# Get tmux option or use default
get_tmux_option() {
    local option="$1"
    local default="$2"
    tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
}

# Main day of week function
main() {
    # Get configuration from tmux options
    local day_format
    local timezone
    local locale
    
    day_format=$(get_tmux_option "@forceline_datetime_day_format" "%a")  # Abbreviated day by default
    timezone=$(get_tmux_option "@forceline_datetime_timezone" "")
    locale=$(get_tmux_option "@forceline_datetime_locale" "")
    
    # Set environment variables for helpers
    export FORCELINE_DATETIME_TIMEZONE="$timezone"
    export FORCELINE_DATETIME_LOCALE="$locale"
    
    # Get and display the day of week
    get_day_of_week "$day_format" "$timezone"
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi