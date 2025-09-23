#!/usr/bin/env bash
# CPU module for tmux-forceline v3.0
# Dedicated CPU monitoring with enhanced performance and temperature support

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/cpu/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/scripts/helpers.sh"
fi

# Get forceline root directory using centralized system
FORCELINE_DIR="$(get_forceline_dir)"

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

# CPU-only command mapping - use centralized or fallback paths
if command -v get_forceline_path >/dev/null 2>&1; then
  cpu_commands=(
    "#($(get_forceline_path "modules/cpu/scripts/cpu_percentage.sh"))"
    "#($(get_forceline_path "modules/cpu/scripts/cpu_icon.sh"))"
    "#($(get_forceline_path "modules/cpu/scripts/cpu_bg_color.sh"))"
    "#($(get_forceline_path "modules/cpu/scripts/cpu_fg_color.sh"))"
    "#($(get_forceline_path "modules/cpu/scripts/cpu_temp.sh"))"
    "#($(get_forceline_path "modules/cpu/scripts/cpu_temp_icon.sh"))"
    "#($(get_forceline_path "modules/cpu/scripts/cpu_temp_bg_color.sh"))"
    "#($(get_forceline_path "modules/cpu/scripts/cpu_temp_fg_color.sh"))"
  )
else
  cpu_commands=(
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/cpu_percentage.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/cpu_icon.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/cpu_bg_color.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/cpu_fg_color.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/cpu_temp.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/cpu_temp_icon.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/cpu_temp_bg_color.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/cpu_temp_fg_color.sh)"
  )
fi

# Use centralized set_tmux_option function

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
