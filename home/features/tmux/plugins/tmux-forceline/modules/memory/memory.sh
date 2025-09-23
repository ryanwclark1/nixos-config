#!/usr/bin/env bash
# Memory monitoring module for tmux-forceline v3.0
# Dedicated system memory (RAM) usage tracking

set -euo pipefail

# Global configuration
readonly SCRIPT_VERSION="3.0"
readonly CACHE_DURATION=5  # Optimized cache for memory monitoring
readonly DEFAULT_TIMEOUT=2 # Memory info is fast to retrieve

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    HELPERS_PATH="$(get_forceline_path "modules/memory/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/scripts/helpers.sh"
fi

# Get forceline root directory using centralized system
FORCELINE_DIR="$(get_forceline_dir)"

# Memory-specific interpolation array
memory_interpolation=(
  "\#{memory_percentage}"
  "\#{memory_icon}" 
  "\#{memory_bg_color}"
  "\#{memory_fg_color}"
)

# Memory-specific commands array - use centralized or fallback paths
if command -v get_forceline_path >/dev/null 2>&1; then
  memory_commands=(
    "#($(get_forceline_path "modules/memory/scripts/memory_percentage.sh"))"
    "#($(get_forceline_path "modules/memory/scripts/memory_icon.sh"))"
    "#($(get_forceline_path "modules/memory/scripts/memory_bg_color.sh"))"
    "#($(get_forceline_path "modules/memory/scripts/memory_fg_color.sh"))"
  )
else
  memory_commands=(
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/memory_percentage.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/memory_icon.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/memory_bg_color.sh)"
    "#(${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/memory_fg_color.sh)"
  )
fi

# Set tmux option with validation
set_tmux_option() {
  local option="$1"
  local value="$2"
  tmux set-option -gq "$option" "$value"
}

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
  # Only update if memory monitoring is enabled
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