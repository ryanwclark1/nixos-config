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

cpu_temp_low_bg_color=""
cpu_temp_medium_bg_color=""
cpu_temp_high_bg_color=""

cpu_temp_low_default_bg_color="#[bg=green]"
cpu_temp_medium_default_bg_color="#[bg=yellow]"
cpu_temp_high_default_bg_color="#[bg=red]"

get_bg_color_settings() {
  cpu_temp_low_bg_color=$(get_tmux_option "@cpu_temp_low_bg_color" "$cpu_temp_low_default_bg_color")
  cpu_temp_medium_bg_color=$(get_tmux_option "@cpu_temp_medium_bg_color" "$cpu_temp_medium_default_bg_color")
  cpu_temp_high_bg_color=$(get_tmux_option "@cpu_temp_high_bg_color" "$cpu_temp_high_default_bg_color")
}

print_bg_color() {
  local cpu_temp
  local cpu_temp_status
  if command -v get_forceline_script >/dev/null 2>&1; then
    cpu_temp=$(get_forceline_script "modules/cpu/scripts/cpu_temp.sh" | sed -e 's/[^0-9.]//')
  else
    cpu_temp=$("${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"/cpu_temp.sh | sed -e 's/[^0-9.]//')
  fi
  cpu_temp_status=$(temp_status "$cpu_temp")
  if [ "$cpu_temp_status" == "low" ]; then
    echo "$cpu_temp_low_bg_color"
  elif [ "$cpu_temp_status" == "medium" ]; then
    echo "$cpu_temp_medium_bg_color"
  elif [ "$cpu_temp_status" == "high" ]; then
    echo "$cpu_temp_high_bg_color"
  fi
}

main() {
  get_bg_color_settings
  print_bg_color
}
main
