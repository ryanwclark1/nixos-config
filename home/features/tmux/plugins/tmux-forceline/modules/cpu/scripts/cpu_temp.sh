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

cpu_temp_format="%2.0f"
cpu_temp_unit="C"

print_cpu_temp() {
  cpu_temp_format=$(get_tmux_option "@cpu_temp_format" "$cpu_temp_format")
  cpu_temp_unit=$(get_tmux_option "@cpu_temp_unit" "$cpu_temp_unit")
  if command_exists "sensors"; then
    local val
    if [[ "$cpu_temp_unit" == F ]]; then
      val="$(sensors -f)"
    else
      val="$(sensors)"
    fi
    echo "$val" | sed -e 's/^Tccd/Core /' | awk -v format="$cpu_temp_format$cpu_temp_unit" '/^Core [0-9]+/ {gsub("[^0-9.]", "", $3); sum+=$3; n+=1} END {printf(format, sum/n)}'
  fi
}

main() {
  print_cpu_temp
}
main
