#!/usr/bin/env bash
# Battery Module for tmux-forceline v3.0
# Integrates with the plugin system and provides Base24 theming

set -euo pipefail

# Source shared utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
source "$UTILS_DIR/source_helpers.sh"

# Battery interpolation variables that will be available in tmux
battery_interpolation=(
    "\#{battery_color_bg}"
    "\#{battery_color_fg}"
    "\#{battery_icon}"
    "\#{battery_percentage}"
    "\#{battery_status}"
)

# Corresponding command implementations using centralized paths
battery_commands=(
  "#($(get_forceline_path "modules/battery/battery_color.sh") bg)"
  "#($(get_forceline_path "modules/battery/battery_color.sh") fg)"
  "#($(get_forceline_path "modules/battery/battery_icon.sh"))"
  "#($(get_forceline_path "modules/battery/battery_percentage.sh"))"
  "#($(get_forceline_path "modules/battery/battery_status.sh"))"
)

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
    local battery_helpers
    battery_helpers="$(get_forceline_path "modules/battery/battery_helpers.sh")"
    "$(get_forceline_path "modules/battery/battery_percentage.sh")" >/dev/null &
    source "$battery_helpers" && battery_status >/dev/null &
}

main
