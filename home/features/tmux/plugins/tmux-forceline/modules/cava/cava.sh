#!/usr/bin/env bash
# Cava audio visualization for tmux-forceline
# Captures single frames for static tmux status bar display
#
# Usage:
#   cava.sh          — Cached one-shot output (default, for tmux #())
#   cava.sh stream   — Continuous streaming mode
#   cava.sh fresh    — Fresh capture (bypass cache)
#   cava.sh test     — Self-test
#
# Configuration (tmux options):
#   @forceline_cava_bars     — Number of bars (default: 16)
#   @forceline_cava_color    — Color mode: none|ansi|tmux|auto (default: none)
#   @forceline_cava_ttl      — Cache TTL in seconds (default: 1)
#   @forceline_cava_symbols  — Bar characters (default: "▁▂▃▄▅▆▇█")
#   @forceline_cava_palette  — 256-color indexes (default: "24,27,33,40,76,178,208,196")

set -euo pipefail

# Source shared utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/utils"
source "$UTILS_DIR/source_helpers.sh"

# --- Configuration ---

BARS=$(get_tmux_option "@forceline_cava_bars" "16")
COLOR_MODE=$(get_tmux_option "@forceline_cava_color" "none")
CACHE_TTL=$(get_tmux_option "@forceline_cava_ttl" "1")
SYMBOLS=$(get_tmux_option "@forceline_cava_symbols" "▁▂▃▄▅▆▇█")
PALETTE=$(get_tmux_option "@forceline_cava_palette" "24,27,33,40,76,178,208,196")
FALLBACK="♪♫♪♫♪♫♪♫"

# Resolve 'auto' color mode: use tmux formatting inside tmux, ansi otherwise
if [[ "$COLOR_MODE" == "auto" ]]; then
  if [[ -n "${TMUX:-}" ]]; then
    COLOR_MODE="tmux"
  elif command_exists tput && [[ "$(tput colors 2>/dev/null)" -ge 256 ]]; then
    COLOR_MODE="ansi"
  else
    COLOR_MODE="none"
  fi
fi

CACHE_DIR=$(get_module_cache_dir "cava")
CACHE_FILE="$CACHE_DIR/output.cache"
CONFIG_FILE="/tmp/cava_forceline_cfg_$$"
NUM_SYMBOLS=${#SYMBOLS}
MAX_RANGE=$((NUM_SYMBOLS - 1))

# --- Cava Config ---

write_cava_config() {
  cat > "$CONFIG_FILE" <<EOF
[general]
bars = $BARS

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = $MAX_RANGE
EOF
}

# --- Rendering ---

# Build awk program that converts cava's semicolon-separated numbers to bar symbols
# with optional color wrapping per bar
build_awk_program() {
  local awk_prog='BEGIN { FS=";" }'

  # Build symbol array
  awk_prog+=' { out=""; for(i=1; i<=NF; i++) { v=int($i); '

  # Clamp value to valid range
  awk_prog+="if(v<0) v=0; if(v>$MAX_RANGE) v=$MAX_RANGE; "

  case "$COLOR_MODE" in
    tmux)
      IFS=',' read -ra colors <<< "$PALETTE"
      local n_colors=${#colors[@]}
      awk_prog+='ci=int(v*'"$n_colors"'/'"$((MAX_RANGE+1))"'); '
      # Build color lookup inline
      local color_cases=""
      for ((j=0; j<n_colors; j++)); do
        color_cases+="if(ci==$j) c=\"#[fg=colour${colors[$j]}]\"; "
      done
      awk_prog+="$color_cases"
      awk_prog+='out=out c; '
      ;;
    ansi)
      IFS=',' read -ra colors <<< "$PALETTE"
      local n_colors=${#colors[@]}
      awk_prog+='ci=int(v*'"$n_colors"'/'"$((MAX_RANGE+1))"'); '
      local color_cases=""
      for ((j=0; j<n_colors; j++)); do
        color_cases+="if(ci==$j) c=\"\033[38;5;${colors[$j]}m\"; "
      done
      awk_prog+="$color_cases"
      awk_prog+='out=out c; '
      ;;
  esac

  # Map value to symbol — build symbol lookup
  local sym_cases=""
  for ((j=0; j<=MAX_RANGE; j++)); do
    sym_cases+="if(v==$j) s=\"${SYMBOLS:$j:1}\"; "
  done
  awk_prog+="$sym_cases"
  awk_prog+='out=out s; '
  awk_prog+='} '

  # Reset color at end of line if coloring
  case "$COLOR_MODE" in
    tmux) awk_prog+='out=out "#[default]"; ' ;;
    ansi) awk_prog+='out=out "\033[0m"; ' ;;
  esac

  awk_prog+='print out; fflush(); }'
  echo "$awk_prog"
}

# --- Capture Modes ---

# Stream continuously (original cava.sh behavior)
stream_output() {
  if ! command_exists cava; then
    echo "$FALLBACK"
    return 1
  fi
  write_cava_config
  local awk_prog
  awk_prog=$(build_awk_program)
  cava -p "$CONFIG_FILE" 2>/dev/null | awk "$awk_prog"
}

# Capture a single frame
capture_frame() {
  if ! command_exists cava; then
    return 1
  fi
  write_cava_config
  local awk_prog raw
  awk_prog=$(build_awk_program)
  raw=$(timeout 2s cava -p "$CONFIG_FILE" 2>/dev/null | head -n 1) || true
  if [[ -n "$raw" ]]; then
    echo "$raw" | awk "$awk_prog"
  fi
}

# Get output with caching (default mode for tmux #())
cached_output() {
  if is_cache_valid "$CACHE_FILE" "$CACHE_TTL"; then
    cat "$CACHE_FILE" 2>/dev/null
    return 0
  fi

  local frame
  frame=$(capture_frame)

  if [[ -n "$frame" ]]; then
    echo "$frame" | tee "$CACHE_FILE" 2>/dev/null
  else
    echo "$FALLBACK" | tee "$CACHE_FILE" 2>/dev/null
  fi
}

# --- Self-test ---

run_test() {
  echo "=== cava module self-test ==="
  echo "cava available: $(command_exists cava && echo "yes" || echo "NO")"
  echo "bars: $BARS  symbols: $SYMBOLS  color: $COLOR_MODE  ttl: ${CACHE_TTL}s"
  echo ""

  if ! command_exists cava; then
    echo "SKIP: cava not installed"
    return 1
  fi

  echo -n "Capturing frame... "
  local frame
  frame=$(capture_frame)
  if [[ -n "$frame" ]]; then
    echo "OK"
    echo "Output: $frame"
  else
    echo "FAIL (no output — is audio playing?)"
    echo "Fallback: $FALLBACK"
  fi
}

# --- Cleanup ---

cleanup() {
  kill %% 2>/dev/null || true
  rm -f "$CONFIG_FILE" 2>/dev/null || true
}
trap cleanup EXIT

# --- Main ---

case "${1:-}" in
  stream)  stream_output ;;
  fresh)   capture_frame || echo "$FALLBACK" ;;
  test)    run_test ;;
  *)       cached_output ;;
esac
