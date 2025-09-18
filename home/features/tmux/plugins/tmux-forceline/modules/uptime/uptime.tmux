#!/usr/bin/env bash
# Uptime Module for tmux-forceline v2.0
# Cross-platform system uptime display

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Uptime interpolation variables that will be available in tmux
uptime_interpolation=(
    "\#{uptime}"
    "\#{uptime_short}"
    "\#{uptime_compact}"
    "\#{uptime_days}"
    "\#{uptime_hours}"
)

# Corresponding command implementations
uptime_commands=(
    "#($CURRENT_DIR/scripts/uptime.sh)"
    "#($CURRENT_DIR/scripts/uptime.sh short)"
    "#($CURRENT_DIR/scripts/uptime.sh compact)"
    "#($CURRENT_DIR/scripts/uptime.sh days)"
    "#($CURRENT_DIR/scripts/uptime.sh hours)"
)

# Helper functions from the tmux plugin system
get_tmux_option() {
    local option="$1"
    local default_value="$2"
    local option_value="$(tmux show-option -gqv "$option")"
    if [ -z "$option_value" ]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
}

set_tmux_option() {
    local option="$1"
    local value="$2"
    tmux set-option -gq "$option" "$value"
}

# Interpolate uptime variables in a string
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#uptime_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${uptime_interpolation[$i]}/${uptime_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with uptime interpolation
update_tmux_option() {
    local option="$1"
    local option_value="$(get_tmux_option "$option")"
    local new_option_value="$(do_interpolation "$option_value")"
    set_tmux_option "$option" "$new_option_value"
}

# Main execution
main() {
    # Make scripts executable
    chmod +x "$CURRENT_DIR/scripts/"*.sh
    
    # Update status-left and status-right to support uptime interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Set default uptime configurations if not already set
    set_tmux_option "@forceline_uptime_format" "$(get_tmux_option "@forceline_uptime_format" "short")"
}

main