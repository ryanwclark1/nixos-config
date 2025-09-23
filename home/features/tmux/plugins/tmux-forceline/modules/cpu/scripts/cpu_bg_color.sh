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

cpu_low_bg_color=""
cpu_medium_bg_color=""
cpu_high_bg_color=""

cpu_low_default_bg_color="#[bg=green]"
cpu_medium_default_bg_color="#[bg=yellow]"
cpu_high_default_bg_color="#[bg=red]"

get_bg_color_settings() {
  cpu_low_bg_color=$(get_tmux_option "@cpu_low_bg_color" "$cpu_low_default_bg_color")
  cpu_medium_bg_color=$(get_tmux_option "@cpu_medium_bg_color" "$cpu_medium_default_bg_color")
  cpu_high_bg_color=$(get_tmux_option "@cpu_high_bg_color" "$cpu_high_default_bg_color")
}

print_bg_color() {
  local cpu_percentage
  local load_status
  if command -v get_forceline_script >/dev/null 2>&1; then
    cpu_percentage=$(get_forceline_script "modules/cpu/scripts/cpu_percentage.sh" | sed -e 's/%//')
  else
    cpu_percentage=$("${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"/cpu_percentage.sh | sed -e 's/%//')
  fi
  load_status=$(load_status "$cpu_percentage" "cpu")
  if [ "$load_status" == "low" ]; then
    echo "$cpu_low_bg_color"
  elif [ "$load_status" == "medium" ]; then
    echo "$cpu_medium_bg_color"
  elif [ "$load_status" == "high" ]; then
    echo "$cpu_high_bg_color"
  fi
}

main() {
  get_bg_color_settings
  print_bg_color
}
main "$@"
