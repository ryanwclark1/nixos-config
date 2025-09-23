#!/usr/bin/env bash
# Graphics memory background color script for tmux-forceline v3.0
# Dynamic background color based on VRAM usage levels

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/graphics_memory/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=scripts/helpers.sh
    source "$CURRENT_DIR/helpers.sh"
fi

# Default background colors for different graphics memory usage levels
graphics_memory_low_bg_color="colour22"     # Dark green for low VRAM usage (< 60%)
graphics_memory_medium_bg_color="colour166" # Orange for medium VRAM usage (60-80%)
graphics_memory_high_bg_color="colour196"   # Red for high VRAM usage (> 80%)

# Get background color based on current graphics memory usage
print_graphics_memory_bg_color() {
  local low_bg medium_bg high_bg
  low_bg=$(get_tmux_option "@graphics_memory_low_bg_color" "$graphics_memory_low_bg_color")
  medium_bg=$(get_tmux_option "@graphics_memory_medium_bg_color" "$graphics_memory_medium_bg_color")
  high_bg=$(get_tmux_option "@graphics_memory_high_bg_color" "$graphics_memory_high_bg_color")
  
  # Get current graphics memory percentage
  local graphics_memory_pct
  graphics_memory_pct=$("$CURRENT_DIR/graphics_memory_percentage.sh" | sed 's/%//')
  
  # Handle N/A or non-numeric values
  if [[ "$graphics_memory_pct" == "N/A" ]] || ! [[ "$graphics_memory_pct" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "$medium_bg"
    return
  fi
  
  # Convert to integer for comparison
  graphics_memory_pct=${graphics_memory_pct%.*}
  
  # Select background color based on usage level
  if [ "$graphics_memory_pct" -ge 80 ]; then
    echo "$high_bg"
  elif [ "$graphics_memory_pct" -ge 60 ]; then
    echo "$medium_bg"
  else
    echo "$low_bg"
  fi
}

# Main function
main() {
  print_graphics_memory_bg_color
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi