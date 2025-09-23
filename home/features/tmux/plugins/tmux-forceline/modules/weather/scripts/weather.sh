#!/usr/bin/env bash
# Weather module for tmux-forceline
# Fetches weather information using wttr.in service

set -euo pipefail

# Source centralized tmux functions
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    # shellcheck source=../../../utils/common.sh
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    get_tmux_option() {
        local option="$1"
        local default="$2"
        tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
    }
    
    set_tmux_option() {
        local option="$1"
        local value="$2"
        tmux set-option -gq "$option" "$value"
    }
    
    get_forceline_dir() {
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    }
    
    log_error() {
        echo "[ERROR] $*" >&2
    }
fi

get_weather() {
  local location=$(get_tmux_option "@forceline_weather_location" "")
  local format=$(get_tmux_option "@forceline_weather_format" "1")
  local units=$(get_tmux_option "@forceline_weather_units" "u")

  # Auto-detect location if not specified
  if [ -z "$location" ]; then
    location=$(curl -s "https://ipinfo.io/city" 2>/dev/null | tr -d '\n' || echo "")
    if [ -z "$location" ]; then
      location="New York"
    fi
  fi

  if [ "$units" != "m" ] && [ "$units" != "u" ]; then
    units="u"
  fi

  curl -s "https://wttr.in/$location?$units&format=$format" 2>/dev/null | sed "s/[[:space:]]km/km/g" | tr -d '\n'
}

main() {
  local interval=$(get_tmux_option "@forceline_weather_interval" "15")
  local update_interval=$((60 * ${interval:-15}))
  local current_time=$(date "+%s")
  local previous_update=$(get_tmux_option "@weather-previous-update-time" "0")
  local delta=$((current_time - ${previous_update:-0}))

  if [ -z "$previous_update" ] || [ "$previous_update" = "0" ] || [ $delta -ge $update_interval ]; then
    local value
    if value=$(get_weather); then
      set_tmux_option "@weather-previous-update-time" "$current_time"
      set_tmux_option "@weather-previous-value" "$value"
      echo -n "$value"
    else
      echo -n "N/A"
    fi
  else
    echo -n "$(get_tmux_option "@weather-previous-value" "N/A")"
  fi
}

main
