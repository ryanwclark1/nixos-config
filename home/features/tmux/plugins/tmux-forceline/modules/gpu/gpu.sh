#!/usr/bin/env bash
# GPU module for tmux-forceline v3.0
# Dedicated GPU monitoring with temperature support and multi-vendor compatibility

set -euo pipefail

# Source shared utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
source "$UTILS_DIR/source_helpers.sh"

# GPU-only interpolation array for focused monitoring
gpu_interpolation=(
  "\#{gpu_percentage}"
  "\#{gpu_icon}"
  "\#{gpu_bg_color}"
  "\#{gpu_fg_color}"
  "\#{gpu_temp}"
  "\#{gpu_temp_icon}"
  "\#{gpu_temp_bg_color}"
  "\#{gpu_temp_fg_color}"
)

# GPU command mapping using centralized paths
THRESHOLD_SCRIPT="$(get_forceline_path "utils/threshold_color.sh")"
PCT_SCRIPT="$(get_forceline_path "modules/gpu/gpu_percentage.sh")"
TEMP_SCRIPT="$(get_forceline_path "modules/gpu/gpu_temp.sh")"

gpu_commands=(
  "#($PCT_SCRIPT)"
  "#($THRESHOLD_SCRIPT gpu icon $PCT_SCRIPT)"
  "#($THRESHOLD_SCRIPT gpu bg $PCT_SCRIPT)"
  "#($THRESHOLD_SCRIPT gpu fg $PCT_SCRIPT)"
  "#($TEMP_SCRIPT)"
  "#($THRESHOLD_SCRIPT gpu_temp icon $TEMP_SCRIPT)"
  "#($THRESHOLD_SCRIPT gpu_temp bg $TEMP_SCRIPT)"
  "#($THRESHOLD_SCRIPT gpu_temp fg $TEMP_SCRIPT)"
)

# Perform GPU-specific interpolation
do_interpolation() {
  local all_interpolated="$1"

  for ((i = 0; i < ${#gpu_commands[@]}; i++)); do
    all_interpolated=${all_interpolated//${gpu_interpolation[$i]}/${gpu_commands[$i]}}
  done

  echo "$all_interpolated"
}

# Update tmux option with GPU interpolation
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
