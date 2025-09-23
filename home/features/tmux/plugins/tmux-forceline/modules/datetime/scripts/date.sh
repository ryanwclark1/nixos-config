#!/usr/bin/env bash
# Date script for tmux-forceline v3.0
# Enhanced date display with timezone and locale support

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

# Main date function
main() {
    # Get configuration from tmux options
    local date_format
    local timezone
    local locale
    
    date_format=$(get_tmux_option "@forceline_datetime_date_format" "%Y-%m-%d")
    timezone=$(get_tmux_option "@forceline_datetime_timezone" "")
    locale=$(get_tmux_option "@forceline_datetime_locale" "")
    
    # Set environment variables for helpers
    export FORCELINE_DATETIME_DATE_FORMAT="$date_format"
    export FORCELINE_DATETIME_TIMEZONE="$timezone"
    export FORCELINE_DATETIME_LOCALE="$locale"
    
    # Get and display the date
    get_date "$date_format" "$timezone"
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi