#!/usr/bin/env bash
# Hostname Module for tmux-forceline v2.0
# Cross-platform hostname display with format options

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Hostname interpolation variables that will be available in tmux
hostname_interpolation=(
    "\#{hostname}"
    "\#{hostname_short}"
    "\#{hostname_long}"
    "\#{hostname_icon}"
)

# Corresponding command implementations
hostname_commands=(
    "#($CURRENT_DIR/scripts/hostname.sh)"
    "#($CURRENT_DIR/scripts/hostname.sh short)"
    "#($CURRENT_DIR/scripts/hostname.sh long)"
    "#($CURRENT_DIR/scripts/hostname.sh icon)"
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

# Interpolate hostname variables in a string
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#hostname_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${hostname_interpolation[$i]}/${hostname_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with hostname interpolation
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
    
    # Update status-left and status-right to support hostname interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Set default hostname configurations if not already set
    set_tmux_option "@forceline_hostname_format" "$(get_tmux_option "@forceline_hostname_format" "short")"
    set_tmux_option "@forceline_hostname_show_icon" "$(get_tmux_option "@forceline_hostname_show_icon" "no")"
}

main