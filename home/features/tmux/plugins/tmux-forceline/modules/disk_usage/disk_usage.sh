#!/usr/bin/env bash
# Disk Usage Module for tmux-forceline v3.0
# Enhanced disk monitoring with configurable paths

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Disk usage interpolation variables that will be available in tmux
disk_usage_interpolation=(
    "\#{disk_usage}"
    "\#{disk_usage_status}"
    "\#{disk_usage_percentage}"
    "\#{disk_usage_used}"
    "\#{disk_usage_available}"
)

# Corresponding command implementations - use centralized or fallback paths
if command -v get_forceline_path >/dev/null 2>&1; then
  disk_usage_commands=(
    "#($(get_forceline_path "modules/disk_usage/scripts/disk_usage_simple.sh"))"
    "#($(get_forceline_path "modules/disk_usage/scripts/disk_usage.sh") status)"
    "#($(get_forceline_path "modules/disk_usage/scripts/disk_usage_simple.sh"))"
    "#(df -h / | awk 'NR==2 {print \$3}')"
    "#(df -h / | awk 'NR==2 {print \$4}')"
  )
else
  disk_usage_commands=(
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/disk_usage_simple.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/disk_usage.sh status)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/disk_usage_simple.sh)"
    "#(df -h / | awk 'NR==2 {print \$3}')"
    "#(df -h / | awk 'NR==2 {print \$4}')"
  )
fi

# Interpolate disk usage variables in a string
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#disk_usage_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${disk_usage_interpolation[$i]}/${disk_usage_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with disk usage interpolation
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
        chmod +x "$(get_forceline_path "modules/disk_usage/scripts")"/*.sh
    else
        chmod +x "${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/"*.sh
    fi
    
    # Update status-left and status-right to support disk usage interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Set default disk usage configurations if not already set
    set_tmux_option "@forceline_disk_usage_path" "$(get_tmux_option "@forceline_disk_usage_path" "/")"
    set_tmux_option "@forceline_disk_usage_format" "$(get_tmux_option "@forceline_disk_usage_format" "percentage")"
    set_tmux_option "@forceline_disk_usage_warning_threshold" "$(get_tmux_option "@forceline_disk_usage_warning_threshold" "80")"
    set_tmux_option "@forceline_disk_usage_critical_threshold" "$(get_tmux_option "@forceline_disk_usage_critical_threshold" "90")"
}

main