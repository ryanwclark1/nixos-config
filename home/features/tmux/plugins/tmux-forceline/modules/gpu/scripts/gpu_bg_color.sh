#!/usr/bin/env bash

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/gpu/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/helpers.sh"
fi

gpu_low_bg_color=""
gpu_medium_bg_color=""
gpu_high_bg_color=""

gpu_low_default_bg_color="#[bg=green]"
gpu_medium_default_bg_color="#[bg=yellow]"
gpu_high_default_bg_color="#[bg=red]"

get_bg_color_settings() {
  gpu_low_bg_color=$(get_tmux_option "@gpu_low_bg_color" "$gpu_low_default_bg_color")
  gpu_medium_bg_color=$(get_tmux_option "@gpu_medium_bg_color" "$gpu_medium_default_bg_color")
  gpu_high_bg_color=$(get_tmux_option "@gpu_high_bg_color" "$gpu_high_default_bg_color")
}

print_bg_color() {
  local gpu_percentage
  local gpu_load_status
  gpu_percentage=$("$CURRENT_DIR"/gpu_percentage.sh | sed -e 's/%//')
  gpu_load_status=$(load_status "$gpu_percentage" "gpu")
  if [ "$gpu_load_status" == "low" ]; then
    echo "$gpu_low_bg_color"
  elif [ "$gpu_load_status" == "medium" ]; then
    echo "$gpu_medium_bg_color"
  elif [ "$gpu_load_status" == "high" ]; then
    echo "$gpu_high_bg_color"
  fi
}

main() {
  get_bg_color_settings
  print_bg_color
}
main "$@"
