#!/usr/bin/env bash
# Battery Module for tmux-forceline v3.0
# Integrates with the plugin system and provides Base24 theming

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Battery interpolation variables that will be available in tmux
battery_interpolation=(
    "\#{battery_color_bg}"
    "\#{battery_color_fg}"
    "\#{battery_icon}"
    "\#{battery_percentage}"
    "\#{battery_status}"
)

# Corresponding command implementations - use centralized or fallback paths
if command -v get_forceline_path >/dev/null 2>&1; then
  battery_commands=(
    "#($(get_forceline_path "modules/battery/scripts/battery_color.sh") bg)"
    "#($(get_forceline_path "modules/battery/scripts/battery_color.sh") fg)"
    "#($(get_forceline_path "modules/battery/scripts/battery_icon.sh"))"
    "#($(get_forceline_path "modules/battery/scripts/battery_percentage.sh"))"
    "#($(get_forceline_path "modules/battery/scripts/battery_status.sh"))"
  )
else
  battery_commands=(
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/battery_color.sh bg)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/battery_color.sh fg)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/battery_icon.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/battery_percentage.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/battery_status.sh)"
  )
fi

# Interpolate battery variables in a string
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#battery_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${battery_interpolation[$i]}/${battery_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with battery interpolation
update_tmux_option() {
    local option="$1"
    local option_value="$(get_tmux_option "$option")"
    local new_option_value="$(do_interpolation "$option_value")"
    set_tmux_option "$option" "$new_option_value"
}

# Main execution
main() {
    # Update status-left and status-right to support battery interpolation
    update_tmux_option "status-right"
    update_tmux_option "status-left"
    
    # Cache initial battery data for performance
    if command -v get_forceline_script >/dev/null 2>&1; then
        get_forceline_script "modules/battery/scripts/battery_percentage.sh" >/dev/null &
        source "$(get_forceline_path "modules/battery/scripts/helpers.sh")" && battery_status >/dev/null &
    else
        "${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/battery_percentage.sh" >/dev/null &
        source "${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/helpers.sh" && battery_status >/dev/null &
    fi
}

main