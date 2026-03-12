#!/usr/bin/env bash
# Memory monitoring module for tmux-forceline v3.0
# Dedicated system memory (RAM) usage tracking

set -euo pipefail

# Source shared utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
source "$UTILS_DIR/source_helpers.sh"

# Memory-specific interpolation array
memory_interpolation=(
  "\#{memory_percentage}"
  "\#{memory_icon}"
  "\#{memory_bg_color}"
  "\#{memory_fg_color}"
)

# Memory command mapping using centralized paths
THRESHOLD_SCRIPT="$(get_forceline_path "utils/threshold_color.sh")"
PCT_SCRIPT="$(get_forceline_path "modules/memory/memory_percentage.sh")"

memory_commands=(
  "#($PCT_SCRIPT)"
  "#($THRESHOLD_SCRIPT memory icon $PCT_SCRIPT)"
  "#($THRESHOLD_SCRIPT memory bg $PCT_SCRIPT)"
  "#($THRESHOLD_SCRIPT memory fg $PCT_SCRIPT)"
)

# Perform memory-specific interpolation
do_interpolation() {
  local all_interpolated="$1"
  for ((i = 0; i < ${#memory_commands[@]}; i++)); do
    all_interpolated=${all_interpolated//${memory_interpolation[$i]}/${memory_commands[$i]}}
  done
  echo "$all_interpolated"
}

# Update tmux options for memory module
update_tmux_option() {
  local option="$1"
  local option_value new_option_value
  option_value=$(get_tmux_option "$option")
  new_option_value=$(do_interpolation "$option_value")
  set_tmux_option "$option" "$new_option_value"
}

# Main memory module function
main() {
  local enabled
  enabled=$(get_tmux_option "@forceline_memory_enabled" "true")

  if [[ "$enabled" == "true" ]]; then
    update_tmux_option "status-right"
    update_tmux_option "status-left"
  fi
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
