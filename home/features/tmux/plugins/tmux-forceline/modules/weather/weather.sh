#!/usr/bin/env bash

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/weather/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/scripts/helpers.sh"
fi

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
  if command -v get_forceline_path >/dev/null 2>&1; then
    weather="$(get_forceline_path "modules/weather/scripts/weather.sh")"
  else
    weather="${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}/scripts/weather.sh"
  fi
  replace_placeholder_in_status_line "weather" "$weather" "status-right"
}

main
