#!/usr/bin/env bash
# Uptime Module for tmux-forceline v3.0
# Cross-platform system uptime display

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Uptime interpolation variables that will be available in tmux
uptime_interpolation=(
    "\#{uptime}"
    "\#{uptime_short}"
    "\#{uptime_compact}"
    "\#{uptime_days}"
    "\#{uptime_hours}"
)

# Corresponding command implementations - use centralized or fallback paths
if command -v get_forceline_path >/dev/null 2>&1; then
  uptime_commands=(
    "#($(get_forceline_path "modules/uptime/scripts/uptime.sh"))"
    "#($(get_forceline_path "modules/uptime/scripts/uptime.sh") short)"
    "#($(get_forceline_path "modules/uptime/scripts/uptime.sh") compact)"
    "#($(get_forceline_path "modules/uptime/scripts/uptime.sh") days)"
    "#($(get_forceline_path "modules/uptime/scripts/uptime.sh") hours)"
  )
else
  uptime_commands=(
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/uptime.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/uptime.sh short)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/uptime.sh compact)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/uptime.sh days)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/uptime.sh hours)"
  )
fi

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
    if command -v get_forceline_path >/dev/null 2>&1; then
        chmod +x "$(get_forceline_path "modules/uptime/scripts")"/*.sh
    else
        chmod +x "${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/"*.sh
    fi
    
    # Update status-left and status-right to support uptime interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Set default uptime configurations if not already set
    set_tmux_option "@forceline_uptime_format" "$(get_tmux_option "@forceline_uptime_format" "short")"
}

main