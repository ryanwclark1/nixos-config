#!/usr/bin/env bash
# Threshold classification and color resolution for tmux-forceline
# Replaces duplicated load_status(), fcomp(), and temp_status() across modules

# Source common.sh for get_tmux_option if not already loaded
if ! command -v get_tmux_option >/dev/null 2>&1; then
  UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$UTILS_DIR/common.sh"
fi

# Float comparison: returns 0 (true) if n1 <= n2
fcomp() {
  awk -v n1="$1" -v n2="$2" 'BEGIN {if (n1<=n2) exit 0; exit 1}'
}

# Classify a percentage value into low/medium/high
# Usage: classify_level <percentage> <module_prefix>
# Reads @<prefix>_medium_thresh and @<prefix>_high_thresh from tmux options
classify_level() {
  local percentage="$1"
  local prefix="$2"
  local medium_thresh high_thresh
  medium_thresh=$(get_tmux_option "@${prefix}_medium_thresh" "30")
  high_thresh=$(get_tmux_option "@${prefix}_high_thresh" "80")
  if fcomp "$high_thresh" "$percentage"; then
    echo "high"
  elif fcomp "$medium_thresh" "$percentage" && fcomp "$percentage" "$high_thresh"; then
    echo "medium"
  else
    echo "low"
  fi
}

# Classify a temperature value into low/medium/high
# Usage: classify_temp <temp> [medium_thresh] [high_thresh]
classify_temp() {
  local temp="$1"
  local medium_thresh="${2:-80}"
  local high_thresh="${3:-90}"
  medium_thresh=$(get_tmux_option "@cpu_temp_medium_thresh" "$medium_thresh")
  high_thresh=$(get_tmux_option "@cpu_temp_high_thresh" "$high_thresh")
  if fcomp "$high_thresh" "$temp"; then
    echo "high"
  elif fcomp "$medium_thresh" "$temp" && fcomp "$temp" "$high_thresh"; then
    echo "medium"
  else
    echo "low"
  fi
}

# Backward compatibility aliases
load_status() { classify_level "$@"; }
temp_status() { classify_temp "$@"; }

export -f fcomp classify_level classify_temp load_status temp_status
