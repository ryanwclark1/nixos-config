#!/usr/bin/env bash
# WAN IP Module for tmux-forceline v2.0
# Enhanced WAN IP detection with intelligent caching

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# WAN IP interpolation variables that will be available in tmux
wan_ip_interpolation=(
    "\#{wan_ip}"
    "\#{wan_ip_status}"
    "\#{wan_ip_color_fg}"
    "\#{wan_ip_color_bg}"
)

# Corresponding command implementations
wan_ip_commands=(
    "#($CURRENT_DIR/scripts/wan_ip.sh)"
    "#($CURRENT_DIR/scripts/wan_ip.sh status)"
    "#($CURRENT_DIR/scripts/wan_ip_color.sh fg)"
    "#($CURRENT_DIR/scripts/wan_ip_color.sh bg)"
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

# Interpolate WAN IP variables in a string
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#wan_ip_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${wan_ip_interpolation[$i]}/${wan_ip_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with WAN IP interpolation
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
    
    # Update status-left and status-right to support WAN IP interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Set default WAN IP configurations if not already set
    set_tmux_option "@forceline_wan_ip_cache_ttl" "$(get_tmux_option "@forceline_wan_ip_cache_ttl" "900")"
    set_tmux_option "@forceline_wan_ip_timeout" "$(get_tmux_option "@forceline_wan_ip_timeout" "3")"
    set_tmux_option "@forceline_wan_ip_providers" "$(get_tmux_option "@forceline_wan_ip_providers" "ipify,icanhazip,checkip")"
    set_tmux_option "@forceline_wan_ip_show_status" "$(get_tmux_option "@forceline_wan_ip_show_status" "no")"
}

main