#!/usr/bin/env bash
# Hostname script for tmux-forceline v2.0
# Enhanced hostname display with format options

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/hostname_helpers.sh"

# Get tmux option or use default
get_tmux_option() {
    local option="$1"
    local default="$2"
    tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
}

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