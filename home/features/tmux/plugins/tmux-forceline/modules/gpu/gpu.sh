#!/usr/bin/env bash
# GPU module for tmux-forceline v3.0
# Dedicated GPU monitoring with temperature support and multi-vendor compatibility

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/gpu/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/scripts/helpers.sh"
fi

# Get forceline root directory using centralized system
FORCELINE_DIR="$(get_forceline_dir)"

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

# GPU-only command mapping - use centralized or fallback paths
if command -v get_forceline_path >/dev/null 2>&1; then
  gpu_commands=(
    "#($(get_forceline_path "modules/gpu/scripts/gpu_percentage.sh"))"
    "#($(get_forceline_path "modules/gpu/scripts/gpu_icon.sh"))"
    "#($(get_forceline_path "modules/gpu/scripts/gpu_bg_color.sh"))"
    "#($(get_forceline_path "modules/gpu/scripts/gpu_fg_color.sh"))"
    "#($(get_forceline_path "modules/gpu/scripts/gpu_temp.sh"))"
    "#($(get_forceline_path "modules/gpu/scripts/gpu_temp_icon.sh"))"
    "#($(get_forceline_path "modules/gpu/scripts/gpu_temp_bg_color.sh"))"
    "#($(get_forceline_path "modules/gpu/scripts/gpu_temp_fg_color.sh"))"
  )
else
  gpu_commands=(
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/gpu_percentage.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/gpu_icon.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/gpu_bg_color.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/gpu_fg_color.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/gpu_temp.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/gpu_temp_icon.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/gpu_temp_bg_color.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/gpu_temp_fg_color.sh)"
  )
fi

# Set tmux option with error handling
set_tmux_option() {
  local option="$1"
  local value="$2"
  
  if ! tmux set-option -gq "$option" "$value"; then
    echo "Warning: Failed to set tmux option '$option'" >&2
    return 1
  fi
}

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