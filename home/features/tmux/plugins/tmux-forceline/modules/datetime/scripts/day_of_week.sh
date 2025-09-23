#!/usr/bin/env bash
# Day of week script for tmux-forceline v3.0
# Displays current day of week with format options

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