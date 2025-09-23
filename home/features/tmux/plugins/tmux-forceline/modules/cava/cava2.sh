#!/usr/bin/env bash
# shellcheck disable=SC2155
#
# cava_stdout_bars.sh — render cava amplitudes to Unicode bars on stdout
#
# Usage:
#   ./cava_stdout_bars.sh [-b BARS] [-s SYMBOLS]
#                         [-c none|ansi|tmux]
#                         [-p C1,C2,...]
#
# Options:
#   -b, --bars N         Number of bars to render (default: 18)
#   -s, --symbols STR    Characters used from low→high amplitude.
#                        Default: "▁▂▃▄▅▆▇█"
#   -c, --color MODE     Color mode: none (default), ansi, or tmux
#   -p, --palette LIST   Comma-separated 256-color indexes (low→high).
#                        Default: 24,27,33,40,76,178,208,196
#
# Notes:
# - Requires `cava` in PATH.
# - Uses cava's ASCII output mode (integers 0..ascii_max_range separated by ';').
# - We map each integer to the corresponding symbol and print one line per frame.
# - With color enabled, amplitudes map to a palette bucket per bar.

set -euo pipefail

# Defaults
BARS=18
SYMBOLS="▁▂▃▄▅▆▇█"
# Color options: none | ansi | tmux
COLOR_MODE="none"
# 256-color palette (low→high). Comma-separated colour indexes.
PALETTE="24,27,33,40,76,178,208,196"

# ---- arg parsing (supports short/long) ---------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--bars)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 2; }
      BARS="$2"; shift 2;;
    -s|--symbols)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 2; }
      SYMBOLS="$2"; shift 2;;
    -c|--color)
      # Optional value: if next token exists and isn't another flag, use it; otherwise auto
      if [[ $# -ge 2 && ! "$2" =~ ^- ]]; then
        COLOR_MODE="$2"; shift 2
      else
        COLOR_MODE="auto"; shift
      fi;;
    -p|--palette)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 2; }
      PALETTE="$2"; shift 2;;
    -h|--help)
      sed -n '1,50p' "$0" | sed -n '1,/^set -euo pipefail/p' | sed '$d'
      exit 0;;
    *)
      echo "error: unknown option '$1' (use -h for help)" >&2; exit 2;;
  esac
done

# ---- sanity checks -----------------------------------------------------------
if ! command -v cava >/dev/null 2>&1; then
  echo "error: cava not found in PATH" >&2
  exit 127
fi

if ! [[ "$BARS" =~ ^[0-9]+$ ]] || (( BARS < 1 )); then
  echo "error: --bars must be a positive integer" >&2
  exit 2
fi

# ascii_max_range is index-based (0..N), so it must be (length-1)
# We split SYMBOLS by characters; bash counts bytes, but these glyphs are single codepoints.
RANGE=$(( ${#SYMBOLS} - 1 ))
if (( RANGE < 0 )); then
  echo "error: --symbols must contain at least one character" >&2
  exit 2
fi

# Validate color mode (accept auto)
case "$COLOR_MODE" in
  none|ansi|tmux|auto) : ;;
  *) echo "error: --color must be one of: none, ansi, tmux, auto" >&2; exit 2;;
esac

# Resolve auto color mode
RUNTIME_COLOR_MODE="$COLOR_MODE"
if [[ "$COLOR_MODE" == "auto" ]]; then
  if [[ -n "${TMUX:-}" ]]; then
    RUNTIME_COLOR_MODE="tmux"
  else
    # if stdout is a terminal and supports many colors, prefer ansi
    if [[ -t 1 ]]; then
      if command -v tput >/dev/null 2>&1 && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
        RUNTIME_COLOR_MODE="ansi"
      else
        RUNTIME_COLOR_MODE="ansi"
      fi
    else
      RUNTIME_COLOR_MODE="ansi"
    fi
  fi
fi

# Normalize palette (remove spaces)
PALETTE="${PALETTE//[[:space:]]/}"
if [[ -z "$PALETTE" || ! "$PALETTE" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
  echo "error: --palette must be a comma-separated list of 0..255" >&2
  exit 2
fi

# ---- temp config & cleanup ---------------------------------------------------
CONFIG_FILE="$(mktemp -t cava_cfg.XXXXXX)"
cleanup() { rm -f "$CONFIG_FILE"; }
trap cleanup EXIT

# Write the cava config.
# - bars: how many columns to output
# - method: raw + stdout target
# - data_format: ascii (0..ascii_max_range)
# - ascii_max_range: tie to number of symbols - 1 so indexes map directly
cat >"$CONFIG_FILE" <<EOF
[general]
bars = ${BARS}

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = ${RANGE}
EOF

# ---- run cava and map values to symbols -------------------------------------
# We:
#  - split on ';'
#  - clamp each field into [0, RANGE]
#  - map to the (index+1)-th symbol (awk arrays are 1-based)
#  - print the concatenated row
#  - fflush() to keep it snappy in pipes
cava -p "$CONFIG_FILE" | \
awk -v syms="$SYMBOLS" -v max="$RANGE" -v mode="$RUNTIME_COLOR_MODE" -v palstr="$PALETTE" -F';' '
BEGIN {
  # split symbols into a[1..n], each a UTF-8 codepoint (works fine here)
  n = split(syms, a, "")
  # parse palette into p[1..m]
  m = split(palstr, p, ",")
}
{
  out = ""
  for (i = 1; i <= NF; i++) {
    v = $i + 0
    if (v < 0) v = 0
    if (v > max) v = max
    # choose colour index from palette based on amplitude bucket
    idx = (max > 0 && m > 0) ? int(v * (m - 1) / max) + 1 : 1
    if (idx < 1) idx = 1
    if (idx > m) idx = m

    sym = a[v + 1]
    if (mode == "ansi") {
      # 256-colour ANSI foreground
      out = out sprintf("\033[38;5;%dm%s", p[idx], sym)
    } else if (mode == "tmux") {
      # tmux format colour
      out = out sprintf("#[fg=colour%d]%s", p[idx], sym)
    } else {
      out = out sym
    }
  }
  # reset colour at end of line
  if (mode == "ansi") {
    print out "\033[0m"
  } else if (mode == "tmux") {
    print out "#[default]"
  } else {
    print out
  }
  fflush()
}
'
