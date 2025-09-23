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
gpu_temp_low_icon=""
gpu_temp_medium_icon=""
gpu_temp_high_icon=""

gpu_temp_low_default_icon="="
gpu_temp_medium_default_icon="≡"
gpu_temp_high_default_icon="≣"

# icons are set as script global variables
get_icon_settings() {
  gpu_temp_low_icon=$(get_tmux_option "@gpu_temp_low_icon" "$gpu_temp_low_default_icon")
  gpu_temp_medium_icon=$(get_tmux_option "@gpu_temp_medium_icon" "$gpu_temp_medium_default_icon")
  gpu_temp_high_icon=$(get_tmux_option "@gpu_temp_high_icon" "$gpu_temp_high_default_icon")
}

print_icon() {
  local gpu_temp
  local gpu_temp_status
  gpu_temp=$("$CURRENT_DIR"/gpu_temp.sh | sed -e 's/[^0-9.]//')
  gpu_temp_status=$(temp_status "$gpu_temp")
  if [ "$gpu_temp_status" == "low" ]; then
    echo "$gpu_temp_low_icon"
  elif [ "$gpu_temp_status" == "medium" ]; then
    echo "$gpu_temp_medium_icon"
  elif [ "$gpu_temp_status" == "high" ]; then
    echo "$gpu_temp_high_icon"
  fi
}

main() {
  get_icon_settings
  print_icon "$1"
}
main "$@"
