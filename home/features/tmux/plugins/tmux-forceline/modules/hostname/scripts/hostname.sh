#!/usr/bin/env bash
# Hostname script for tmux-forceline v3.0
# Enhanced hostname display with format options

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/hostname/scripts/hostname_helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/hostname_helpers.sh"
fi

# Main hostname function
main() {
    # Get configuration from tmux options
    local hostname_format
    local hostname_custom
    local show_icon
    
    hostname_format=$(get_tmux_option "@forceline_hostname_format" "short")
    hostname_custom=$(get_tmux_option "@forceline_hostname_custom" "")
    show_icon=$(get_tmux_option "@forceline_hostname_show_icon" "no")
    
    # Set environment variables for helpers
    export FORCELINE_HOSTNAME_FORMAT="$hostname_format"
    export FORCELINE_HOSTNAME_CUSTOM="$hostname_custom"
    
    # Get and display the hostname
    get_hostname_with_icon "$hostname_format" "$hostname_custom" "$show_icon"
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi