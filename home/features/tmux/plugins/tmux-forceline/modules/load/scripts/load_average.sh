#!/usr/bin/env bash
# Load average script for tmux-forceline v3.0
# Enhanced system load monitoring with color indication

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/load/scripts/load_helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/load_helpers.sh"
fi

# Main load average function
main() {
    # Get configuration from tmux options
    local load_format
    local load_precision
    local show_color
    
    load_format=$(get_tmux_option "@forceline_load_format" "average")
    load_precision=$(get_tmux_option "@forceline_load_precision" "1")
    show_color=$(get_tmux_option "@forceline_load_show_color" "no")
    
    # Set environment variables for helpers
    export FORCELINE_LOAD_FORMAT="$load_format"
    export FORCELINE_LOAD_PRECISION="$load_precision"
    
    # Get and display the load average
    get_load_with_color "$load_format" "$load_precision" "$show_color"
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi