#!/usr/bin/env bash
# Memory foreground color script for tmux-forceline v3.0
# Dynamic foreground color based on memory usage levels

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

# Default foreground colors for different memory usage levels
memory_low_fg_color="colour231"     # White for memory usage < 60%
memory_medium_fg_color="colour16"   # Black for memory usage 60-80%
memory_high_fg_color="colour231"    # White for memory usage > 80%

# Get foreground color based on current memory usage
print_memory_fg_color() {
  local low_fg medium_fg high_fg
  low_fg=$(get_tmux_option "@memory_low_fg_color" "$memory_low_fg_color")
  medium_fg=$(get_tmux_option "@memory_medium_fg_color" "$memory_medium_fg_color")
  high_fg=$(get_tmux_option "@memory_high_fg_color" "$memory_high_fg_color")
  
  # Get current memory percentage
  local memory_pct
  if command -v get_forceline_script >/dev/null 2>&1; then
    memory_pct=$(get_forceline_script "modules/memory/scripts/memory_percentage.sh" | sed 's/%//')
  else
    memory_pct=$("${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/memory_percentage.sh" | sed 's/%//')
  fi
  
  # Handle non-numeric values
  if ! [[ "$memory_pct" =~ ^[0-9]+(\\.[0-9]+)?$ ]]; then
    echo "$medium_fg"
    return
  fi
  
  # Convert to integer for comparison
  memory_pct=${memory_pct%.*}
  
  # Select foreground color based on usage level
  if [ "$memory_pct" -ge 80 ]; then
    echo "$high_fg"
  elif [ "$memory_pct" -ge 60 ]; then
    echo "$medium_fg"
  else
    echo "$low_fg"
  fi
}

# Main function
main() {
  print_memory_fg_color
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi