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

# script global variables
gpu_low_icon=""
gpu_medium_icon=""
gpu_high_icon=""

gpu_low_default_icon="="
gpu_medium_default_icon="≡"
gpu_high_default_icon="≣"

# icons are set as script global variables
get_icon_settings() {
  gpu_low_icon=$(get_tmux_option "@gpu_low_icon" "$gpu_low_default_icon")
  gpu_medium_icon=$(get_tmux_option "@gpu_medium_icon" "$gpu_medium_default_icon")
  gpu_high_icon=$(get_tmux_option "@gpu_high_icon" "$gpu_high_default_icon")
}

print_icon() {
  local gpu_percentage
  local gpu_load_status
  gpu_percentage=$("$CURRENT_DIR"/gpu_percentage.sh | sed -e 's/%//')
  gpu_load_status=$(load_status "$gpu_percentage" "gpu")
  if [ "$gpu_load_status" == "low" ]; then
    echo "$gpu_low_icon"
  elif [ "$gpu_load_status" == "medium" ]; then
    echo "$gpu_medium_icon"
  elif [ "$gpu_load_status" == "high" ]; then
    echo "$gpu_high_icon"
  fi
}

main() {
  get_icon_settings
  print_icon "$1"
}
main "$@"
