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
cpu_temp_low_icon=""
cpu_temp_medium_icon=""
cpu_temp_high_icon=""

cpu_temp_low_default_icon="="
cpu_temp_medium_default_icon="≡"
cpu_temp_high_default_icon="≣"

# icons are set as script global variables
get_icon_settings() {
  cpu_temp_low_icon=$(get_tmux_option "@cpu_temp_low_icon" "$cpu_temp_low_default_icon")
  cpu_temp_medium_icon=$(get_tmux_option "@cpu_temp_medium_icon" "$cpu_temp_medium_default_icon")
  cpu_temp_high_icon=$(get_tmux_option "@cpu_temp_high_icon" "$cpu_temp_high_default_icon")
}

print_icon() {
  local cpu_temp
  local cpu_temp_status
  if command -v get_forceline_script >/dev/null 2>&1; then
    cpu_temp=$(get_forceline_script "modules/cpu/scripts/cpu_temp.sh" | sed -e 's/[^0-9.]//')
  else
    cpu_temp=$("${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"/cpu_temp.sh | sed -e 's/[^0-9.]//')
  fi
  cpu_temp_status=$(temp_status "$cpu_temp")
  if [ "$cpu_temp_status" == "low" ]; then
    echo "$cpu_temp_low_icon"
  elif [ "$cpu_temp_status" == "medium" ]; then
    echo "$cpu_temp_medium_icon"
  elif [ "$cpu_temp_status" == "high" ]; then
    echo "$cpu_temp_high_icon"
  fi
}

main() {
  get_icon_settings
  print_icon "$1"
}
main "$@"
