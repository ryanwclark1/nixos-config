#!/usr/bin/env bash
# Generic threshold-based color/icon resolver for tmux-forceline
# Replaces 19+ individual *_bg_color.sh, *_fg_color.sh, *_icon.sh scripts
#
# Usage: threshold_color.sh <module> <type> <cmd...>
#   module: cpu, gpu, memory, graphics_memory, cpu_temp, gpu_temp
#   type: bg, fg, icon
#   cmd: command (and optional args) that outputs the current percentage

set -euo pipefail

# Source shared utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/platform.sh"
source "$UTILS_DIR/thresholds.sh"

MODULE="${1:?Usage: threshold_color.sh <module> <type> [cmd...]}"
TYPE="${2:?Usage: threshold_color.sh <module> <type> [cmd...]}"
shift 2
PCT_CMD=("$@")

# Default color/icon tables per module
# Format: module_type_level
declare -A DEFAULTS=(
  # CPU colors
  [cpu_bg_low]="#[bg=green]"     [cpu_bg_medium]="#[bg=yellow]"     [cpu_bg_high]="#[bg=red]"
  [cpu_fg_low]="#[fg=green]"     [cpu_fg_medium]="#[fg=yellow]"     [cpu_fg_high]="#[fg=red]"
  [cpu_icon_low]="="             [cpu_icon_medium]="≡"              [cpu_icon_high]="≣"
  # CPU temp (same defaults)
  [cpu_temp_bg_low]="#[bg=green]"   [cpu_temp_bg_medium]="#[bg=yellow]"   [cpu_temp_bg_high]="#[bg=red]"
  [cpu_temp_fg_low]="#[fg=green]"   [cpu_temp_fg_medium]="#[fg=yellow]"   [cpu_temp_fg_high]="#[fg=red]"
  [cpu_temp_icon_low]="="          [cpu_temp_icon_medium]="≡"            [cpu_temp_icon_high]="≣"
  # GPU colors (same as CPU)
  [gpu_bg_low]="#[bg=green]"     [gpu_bg_medium]="#[bg=yellow]"     [gpu_bg_high]="#[bg=red]"
  [gpu_fg_low]="#[fg=green]"     [gpu_fg_medium]="#[fg=yellow]"     [gpu_fg_high]="#[fg=red]"
  [gpu_icon_low]="="             [gpu_icon_medium]="≡"              [gpu_icon_high]="≣"
  # GPU temp
  [gpu_temp_bg_low]="#[bg=green]"   [gpu_temp_bg_medium]="#[bg=yellow]"   [gpu_temp_bg_high]="#[bg=red]"
  [gpu_temp_fg_low]="#[fg=green]"   [gpu_temp_fg_medium]="#[fg=yellow]"   [gpu_temp_fg_high]="#[fg=red]"
  [gpu_temp_icon_low]="="          [gpu_temp_icon_medium]="≡"            [gpu_temp_icon_high]="≣"
  # Memory colors
  [memory_bg_low]="colour22"     [memory_bg_medium]="colour136"     [memory_bg_high]="colour160"
  [memory_fg_low]="colour231"    [memory_fg_medium]="colour16"      [memory_fg_high]="colour231"
  [memory_icon_low]="󰾭"         [memory_icon_medium]="󰾯"          [memory_icon_high]="󰓅"
  # Graphics memory colors
  [graphics_memory_bg_low]="colour22"   [graphics_memory_bg_medium]="colour166"   [graphics_memory_bg_high]="colour196"
  [graphics_memory_fg_low]="colour231"  [graphics_memory_fg_medium]="colour16"    [graphics_memory_fg_high]="colour231"
  [graphics_memory_icon_low]="="        [graphics_memory_icon_medium]="≡"         [graphics_memory_icon_high]="≣"
)

# Determine the threshold prefix for classify_level
# cpu_temp and gpu_temp use classify_temp, others use classify_level
get_level() {
  local pct="$1"
  case "$MODULE" in
    cpu_temp|gpu_temp)
      classify_temp "$pct"
      ;;
    memory|graphics_memory)
      # These modules use hardcoded 60/80 thresholds (not tmux options)
      local pct_int="${pct%.*}"
      if [ "$pct_int" -ge 80 ] 2>/dev/null; then
        echo "high"
      elif [ "$pct_int" -ge 60 ] 2>/dev/null; then
        echo "medium"
      else
        echo "low"
      fi
      ;;
    *)
      classify_level "$pct" "$MODULE"
      ;;
  esac
}

# Get the configured or default value for a module/type/level combination
get_value() {
  local level="$1"
  local option_name="@${MODULE}_${level}_${TYPE}_color"
  # For icons, the option name is different
  if [[ "$TYPE" == "icon" ]]; then
    option_name="@${MODULE}_${level}_${TYPE}"
  fi
  # Also try the simpler @module_level_type pattern
  local default="${DEFAULTS[${MODULE}_${TYPE}_${level}]:-}"
  get_tmux_option "$option_name" "$default"
}

main() {
  # Get current percentage
  local pct
  if [[ ${#PCT_CMD[@]} -gt 0 ]] && [[ -x "${PCT_CMD[0]}" ]]; then
    pct=$("${PCT_CMD[@]}" | sed -e 's/%//' -e 's/[^0-9.]//g')
  else
    echo "${DEFAULTS[${MODULE}_${TYPE}_low]:-}"
    return
  fi

  # Handle non-numeric values
  if ! [[ "$pct" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "${DEFAULTS[${MODULE}_${TYPE}_medium]:-}"
    return
  fi

  local level
  level=$(get_level "$pct")
  get_value "$level"
}

main
