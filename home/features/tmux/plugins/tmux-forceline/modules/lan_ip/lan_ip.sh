#!/usr/bin/env bash
# LAN IP Module for tmux-forceline v3.0
# Local network IP detection with interface selection

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# LAN IP interpolation variables that will be available in tmux
lan_ip_interpolation=(
    "\#{lan_ip}"
    "\#{lan_ip_primary}"
    "\#{lan_ip_all}"
)

# Corresponding command implementations - use centralized or fallback paths
if command -v get_forceline_path >/dev/null 2>&1; then
  lan_ip_commands=(
    "#($(get_forceline_path "modules/lan_ip/scripts/lan_ip.sh"))"
    "#($(get_forceline_path "modules/lan_ip/scripts/lan_ip.sh") primary)"
    "#($(get_forceline_path "modules/lan_ip/scripts/lan_ip.sh") all)"
  )
else
  lan_ip_commands=(
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/lan_ip.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/lan_ip.sh primary)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/lan_ip.sh all)"
  )
fi

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
    if command -v get_forceline_path >/dev/null 2>&1; then
        chmod +x "$(get_forceline_path "modules/lan_ip/scripts")"/*.sh
    else
        chmod +x "${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/"*.sh
    fi
    
    # Update status-left and status-right to support LAN IP interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Set default LAN IP configurations if not already set
    set_tmux_option "@forceline_lan_ip_format" "$(get_tmux_option "@forceline_lan_ip_format" "primary")"
    set_tmux_option "@forceline_lan_ip_interface" "$(get_tmux_option "@forceline_lan_ip_interface" "")"
    set_tmux_option "@forceline_lan_ip_show_interface" "$(get_tmux_option "@forceline_lan_ip_show_interface" "no")"
}

main