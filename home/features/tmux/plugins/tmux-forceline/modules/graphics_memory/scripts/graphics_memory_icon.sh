#!/usr/bin/env bash
# Graphics memory icon script for tmux-forceline v3.0
# Dynamic GPU memory icon based on VRAM usage levels and vendor detection

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

# Default icons for different graphics memory usage levels
graphics_memory_low_icon="<�"      # Gaming controller for low VRAM usage (< 60%)
graphics_memory_medium_icon="=�"   # Desktop computer for medium VRAM usage (60-80%)
graphics_memory_high_icon="=%"     # Fire for high VRAM usage (> 80%)

# Get icon based on current graphics memory usage
print_graphics_memory_icon() {
  local low_icon medium_icon high_icon
  low_icon=$(get_tmux_option "@graphics_memory_low_icon" "$graphics_memory_low_icon")
  medium_icon=$(get_tmux_option "@graphics_memory_medium_icon" "$graphics_memory_medium_icon")
  high_icon=$(get_tmux_option "@graphics_memory_high_icon" "$graphics_memory_high_icon")
  
  # Get current graphics memory percentage
  local graphics_memory_pct
  graphics_memory_pct=$("$CURRENT_DIR/graphics_memory_percentage.sh" | sed 's/%//')
  
  # Handle N/A or non-numeric values
  if [[ "$graphics_memory_pct" == "N/A" ]] || ! [[ "$graphics_memory_pct" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    # Default icon for unavailable graphics memory info
    echo "<�"  # Bullseye for unknown/unavailable state
    return
  fi
  
  # Convert to integer for comparison
  graphics_memory_pct=${graphics_memory_pct%.*}
  
  # Select icon based on usage level
  if [ "$graphics_memory_pct" -ge 80 ]; then
    echo "$high_icon"
  elif [ "$graphics_memory_pct" -ge 60 ]; then
    echo "$medium_icon"
  else
    echo "$low_icon"
  fi
}

# Main function
main() {
  print_graphics_memory_icon
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi