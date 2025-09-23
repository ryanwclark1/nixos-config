#!/usr/bin/env bash
# Graphics Memory module for tmux-forceline v3.0
# Dedicated VRAM/GPU memory monitoring with multi-vendor compatibility

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Source helpers using centralized or fallback path management
if command -v get_forceline_path >/dev/null 2>&1; then
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/graphics_memory/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    # shellcheck source=scripts/helpers.sh
    source "${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/helpers.sh"
fi

# Get forceline root directory using centralized system
FORCELINE_DIR="$(get_forceline_dir)"

# Graphics memory interpolation array for focused monitoring
graphics_memory_interpolation=(
  "\\#{graphics_memory_percentage}"
  "\\#{graphics_memory_icon}"
  "\\#{graphics_memory_bg_color}"
  "\\#{graphics_memory_fg_color}"
)

# Graphics memory command mapping
graphics_memory_commands=(
  "#($CURRENT_DIR/scripts/graphics_memory_percentage.sh)"
  "#($CURRENT_DIR/scripts/graphics_memory_icon.sh)"
  "#($CURRENT_DIR/scripts/graphics_memory_bg_color.sh)"
  "#($CURRENT_DIR/scripts/graphics_memory_fg_color.sh)"
)

# Set tmux option with error handling
set_tmux_option() {
  local option="$1"
  local value="$2"
  
  if ! tmux set-option -gq "$option" "$value"; then
    echo "Warning: Failed to set tmux option '$option'" >&2
    return 1
  fi
}

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