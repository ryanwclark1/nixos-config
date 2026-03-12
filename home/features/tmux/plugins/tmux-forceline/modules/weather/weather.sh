#!/usr/bin/env bash

# Source shared utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
source "$UTILS_DIR/source_helpers.sh"

replace_placeholder_in_status_line() {
  local placeholder="\#{$1}"
  local script="#($2)"
  local status_line_side=$3
  local old_status_line=$(get_tmux_option $status_line_side)
  local new_status_line=${old_status_line/$placeholder/$script}

  $(set_tmux_option $status_line_side "$new_status_line")
}

main() {
  local weather
  weather="$(get_forceline_path "modules/weather/weather_data.sh")"
  replace_placeholder_in_status_line "weather" "$weather" "status-right"
}

main
