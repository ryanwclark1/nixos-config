#!/usr/bin/env bash
# LAN IP Module for tmux-forceline v2.0
# Local network IP detection with interface selection

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# LAN IP interpolation variables that will be available in tmux
lan_ip_interpolation=(
    "\#{lan_ip}"
    "\#{lan_ip_primary}"
    "\#{lan_ip_all}"
)

# Corresponding command implementations
lan_ip_commands=(
    "#($CURRENT_DIR/scripts/lan_ip.sh)"
    "#($CURRENT_DIR/scripts/lan_ip.sh primary)"
    "#($CURRENT_DIR/scripts/lan_ip.sh all)"
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

# Interpolate LAN IP variables in a string
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#lan_ip_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${lan_ip_interpolation[$i]}/${lan_ip_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with LAN IP interpolation
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
    
    # Update status-left and status-right to support LAN IP interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Set default LAN IP configurations if not already set
    set_tmux_option "@forceline_lan_ip_format" "$(get_tmux_option "@forceline_lan_ip_format" "primary")"
    set_tmux_option "@forceline_lan_ip_interface" "$(get_tmux_option "@forceline_lan_ip_interface" "")"
    set_tmux_option "@forceline_lan_ip_show_interface" "$(get_tmux_option "@forceline_lan_ip_show_interface" "no")"
}

main