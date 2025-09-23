#!/usr/bin/env bash

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/cpu/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/helpers.sh"
fi

# script global variables
cpu_low_icon=""
cpu_medium_icon=""
cpu_high_icon=""

cpu_low_default_icon="="
cpu_medium_default_icon="≡"
cpu_high_default_icon="≣"

# icons are set as script global variables
get_icon_settings() {
  cpu_low_icon=$(get_tmux_option "@cpu_low_icon" "$cpu_low_default_icon")
  cpu_medium_icon=$(get_tmux_option "@cpu_medium_icon" "$cpu_medium_default_icon")
  cpu_high_icon=$(get_tmux_option "@cpu_high_icon" "$cpu_high_default_icon")
}

print_icon() {
  local cpu_percentage
  local load_status
  if command -v get_forceline_script >/dev/null 2>&1; then
    cpu_percentage=$(get_forceline_script "modules/cpu/scripts/cpu_percentage.sh" | sed -e 's/%//')
  else
    cpu_percentage=$("${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"/cpu_percentage.sh | sed -e 's/%//')
  fi
  load_status=$(load_status "$cpu_percentage" "cpu")
  if [ "$load_status" == "low" ]; then
    echo "$cpu_low_icon"
  elif [ "$load_status" == "medium" ]; then
    echo "$cpu_medium_icon"
  elif [ "$load_status" == "high" ]; then
    echo "$cpu_high_icon"
  fi
}

main() {
  get_icon_settings
  print_icon "$1"
}
main "$@"
