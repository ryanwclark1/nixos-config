#!/usr/bin/env bash
# WAN IP Module for tmux-forceline v3.0
# Enhanced WAN IP detection with intelligent caching

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# WAN IP interpolation variables that will be available in tmux
wan_ip_interpolation=(
    "\#{wan_ip}"
    "\#{wan_ip_status}"
    "\#{wan_ip_color_fg}"
    "\#{wan_ip_color_bg}"
)

# Corresponding command implementations - use centralized or fallback paths
if command -v get_forceline_path >/dev/null 2>&1; then
  wan_ip_commands=(
    "#($(get_forceline_path "modules/wan_ip/scripts/wan_ip.sh"))"
    "#($(get_forceline_path "modules/wan_ip/scripts/wan_ip.sh") status)"
    "#($(get_forceline_path "modules/wan_ip/scripts/wan_ip_color.sh") fg)"
    "#($(get_forceline_path "modules/wan_ip/scripts/wan_ip_color.sh") bg)"
  )
else
  wan_ip_commands=(
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/wan_ip.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/wan_ip.sh status)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/wan_ip_color.sh fg)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/wan_ip_color.sh bg)"
  )
fi

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
    if command -v get_forceline_path >/dev/null 2>&1; then
        chmod +x "$(get_forceline_path "modules/wan_ip/scripts")"/*.sh
    else
        chmod +x "${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/"*.sh
    fi
    
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