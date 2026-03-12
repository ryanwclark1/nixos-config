#!/usr/bin/env bash
# Graphics Memory module for tmux-forceline v3.0
# Dedicated VRAM/GPU memory monitoring with multi-vendor compatibility

set -euo pipefail

# Source shared utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
source "$UTILS_DIR/source_helpers.sh"

# Graphics memory interpolation array for focused monitoring
graphics_memory_interpolation=(
  "\\#{graphics_memory_percentage}"
  "\\#{graphics_memory_icon}"
  "\\#{graphics_memory_bg_color}"
  "\\#{graphics_memory_fg_color}"
)

# Graphics memory command mapping using centralized paths
THRESHOLD_SCRIPT="$(get_forceline_path "utils/threshold_color.sh")"
PCT_SCRIPT="$(get_forceline_path "modules/graphics_memory/graphics_memory_percentage.sh")"

graphics_memory_commands=(
  "#($PCT_SCRIPT)"
  "#($THRESHOLD_SCRIPT graphics_memory icon $PCT_SCRIPT)"
  "#($THRESHOLD_SCRIPT graphics_memory bg $PCT_SCRIPT)"
  "#($THRESHOLD_SCRIPT graphics_memory fg $PCT_SCRIPT)"
)

# Perform graphics memory-specific interpolation
do_interpolation() {
  local all_interpolated="$1"

  for ((i = 0; i < ${#graphics_memory_commands[@]}; i++)); do
    all_interpolated=${all_interpolated//${graphics_memory_interpolation[$i]}/${graphics_memory_commands[$i]}}
  done

  echo "$all_interpolated"
}

# Update tmux option with graphics memory interpolation
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
