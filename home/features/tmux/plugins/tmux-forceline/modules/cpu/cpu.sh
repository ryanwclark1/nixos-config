#!/usr/bin/env bash
# CPU module for tmux-forceline v3.0
# Dedicated CPU monitoring with enhanced performance and temperature support

set -euo pipefail

# Source shared utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
source "$UTILS_DIR/source_helpers.sh"

# CPU-only interpolation array for focused monitoring
cpu_interpolation=(
  "\#{cpu_percentage}"
  "\#{cpu_icon}"
  "\#{cpu_bg_color}"
  "\#{cpu_fg_color}"
  "\#{cpu_temp}"
  "\#{cpu_temp_icon}"
  "\#{cpu_temp_bg_color}"
  "\#{cpu_temp_fg_color}"
)

# CPU command mapping using centralized paths
# Color/icon scripts use generic threshold_color.sh
THRESHOLD_SCRIPT="$(get_forceline_path "utils/threshold_color.sh")"
PCT_SCRIPT="$(get_forceline_path "modules/cpu/cpu_percentage.sh")"
TEMP_SCRIPT="$(get_forceline_path "modules/cpu/cpu_temp.sh")"

cpu_commands=(
  "#($PCT_SCRIPT)"
  "#($THRESHOLD_SCRIPT cpu icon $PCT_SCRIPT)"
  "#($THRESHOLD_SCRIPT cpu bg $PCT_SCRIPT)"
  "#($THRESHOLD_SCRIPT cpu fg $PCT_SCRIPT)"
  "#($TEMP_SCRIPT)"
  "#($THRESHOLD_SCRIPT cpu_temp icon $TEMP_SCRIPT)"
  "#($THRESHOLD_SCRIPT cpu_temp bg $TEMP_SCRIPT)"
  "#($THRESHOLD_SCRIPT cpu_temp fg $TEMP_SCRIPT)"
)

# Perform CPU-specific interpolation
do_interpolation() {
  local all_interpolated="$1"

  for ((i = 0; i < ${#cpu_commands[@]}; i++)); do
    all_interpolated=${all_interpolated//${cpu_interpolation[$i]}/${cpu_commands[$i]}}
  done

  echo "$all_interpolated"
}

# Update tmux option with CPU interpolation
update_tmux_option() {
  local option="$1"
  local option_value new_option_value

  option_value=$(get_tmux_option "$option")
  new_option_value=$(do_interpolation "$option_value")
  set_tmux_option "$option" "$new_option_value"
}

# Main function
main() {
  update_tmux_option "status-right"
  update_tmux_option "status-left"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
