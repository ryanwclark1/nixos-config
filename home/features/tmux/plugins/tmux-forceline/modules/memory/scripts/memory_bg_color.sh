#!/usr/bin/env bash
# Memory background color script for tmux-forceline v3.0
# Dynamic background color based on memory usage levels

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

# Default background colors for different memory usage levels
memory_low_bg_color="colour22"      # Dark green for memory usage < 60%
memory_medium_bg_color="colour136"  # Orange for memory usage 60-80%
memory_high_bg_color="colour160"    # Red for memory usage > 80%

# Get background color based on current memory usage
print_memory_bg_color() {
  local low_bg medium_bg high_bg
  low_bg=$(get_tmux_option "@memory_low_bg_color" "$memory_low_bg_color")
  medium_bg=$(get_tmux_option "@memory_medium_bg_color" "$memory_medium_bg_color")
  high_bg=$(get_tmux_option "@memory_high_bg_color" "$memory_high_bg_color")
  
  # Get current memory percentage
  local memory_pct
  if command -v get_forceline_script >/dev/null 2>&1; then
    memory_pct=$(get_forceline_script "modules/memory/scripts/memory_percentage.sh" | sed 's/%//')
  else
    memory_pct=$("${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/memory_percentage.sh" | sed 's/%//')
  fi
  
  # Handle non-numeric values
  if ! [[ "$memory_pct" =~ ^[0-9]+(\\.[0-9]+)?$ ]]; then
    echo "$medium_bg"
    return
  fi
  
  # Convert to integer for comparison
  memory_pct=${memory_pct%.*}
  
  # Select background color based on usage level
  if [ "$memory_pct" -ge 80 ]; then
    echo "$high_bg"
  elif [ "$memory_pct" -ge 60 ]; then
    echo "$medium_bg"
  else
    echo "$low_bg"
  fi
}

# Main function
main() {
  print_memory_bg_color
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi