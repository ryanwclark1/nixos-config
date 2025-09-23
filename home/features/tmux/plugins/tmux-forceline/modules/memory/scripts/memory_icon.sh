#!/usr/bin/env bash
# Memory icon script for tmux-forceline v3.0
# Dynamic memory icon based on usage levels

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/memory/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/helpers.sh"
fi

# Default memory icons for different usage levels
memory_low_icon="󰾭"      # Memory usage < 60%
memory_medium_icon="󰾯"    # Memory usage 60-80%
memory_high_icon="󰓅"      # Memory usage > 80%

# Get memory icon based on current usage
print_memory_icon() {
  local low_icon medium_icon high_icon
  low_icon=$(get_tmux_option "@memory_low_icon" "$memory_low_icon")
  medium_icon=$(get_tmux_option "@memory_medium_icon" "$memory_medium_icon")
  high_icon=$(get_tmux_option "@memory_high_icon" "$memory_high_icon")
  
  # Get current memory percentage
  local memory_pct
  if command -v get_forceline_script >/dev/null 2>&1; then
    memory_pct=$(get_forceline_script "modules/memory/scripts/memory_percentage.sh" | sed 's/%//')
  else
    memory_pct=$("${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/memory_percentage.sh" | sed 's/%//')
  fi
  
  # Handle non-numeric values
  if ! [[ "$memory_pct" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "$medium_icon"
    return
  fi
  
  # Convert to integer for comparison
  memory_pct=${memory_pct%.*}
  
  # Select icon based on usage level
  if [ "$memory_pct" -ge 80 ]; then
    echo "$high_icon"
  elif [ "$memory_pct" -ge 60 ]; then
    echo "$medium_icon"
  else
    echo "$low_icon"
  fi
}

# Main function
main() {
  print_memory_icon
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi