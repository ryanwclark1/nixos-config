#!/usr/bin/env bash
# Screenshot capture script for ScreenshotService
# Usage: qs-screenshot <mode> [monitor]
# Modes: region, screen, fullscreen

set -uo pipefail

MODE="${1:-region}"
MONITOR="${2:-}"
DEFAULT_PICTURES_DIR="${HOME}/Pictures"

if [[ -f "${HOME}/.config/user-dirs.dirs" ]]; then
  # shellcheck disable=SC1090
  source "${HOME}/.config/user-dirs.dirs"
fi

PICTURES_DIR="${XDG_PICTURES_DIR:-$DEFAULT_PICTURES_DIR}"
PICTURES_DIR="${PICTURES_DIR%/}"
SCREENSHOTS_DIR="${SCREENSHOTS_DIR:-${PICTURES_DIR}/Screenshots}"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S-%3N)"
FILEPATH="${SCREENSHOTS_DIR}/screenshot_${TIMESTAMP}.png"

emit_error() {
  echo "ERROR|$1"
}

ensure_output_dir() {
  if ! mkdir -p "$SCREENSHOTS_DIR" 2>/dev/null; then
    emit_error "unable to create screenshots directory: $SCREENSHOTS_DIR"
    exit 1
  fi
}

copy_to_clipboard() {
  if command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$FILEPATH" >/dev/null 2>&1 || true
  fi
}

# Freeze screen for region selection if hyprpicker is available
freezescreen() {
  if command -v hyprpicker >/dev/null 2>&1; then
    hyprpicker -rz &
    HYPRPICKER_PID=$!
    sleep 0.2
  fi
}

unfreezescreen() {
  if [[ -n "${HYPRPICKER_PID:-}" ]]; then
    kill "$HYPRPICKER_PID" 2>/dev/null || true
  fi
  pkill hyprpicker 2>/dev/null || true
}

capture_region() {
  if ! command -v slurp >/dev/null 2>&1; then
    emit_error "missing dependency: slurp"
    exit 1
  fi
  
  # Try to get window rectangles if on Hyprland for better slurp experience
  local rects=""
  if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    rects=$(hyprctl clients -j | jq -r '.[] | select(.workspace.id != -1) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null || echo "")
  fi

  freezescreen
  
  local geometry
  if [[ -n "$rects" ]]; then
    geometry=$(echo "$rects" | slurp 2>/dev/null) || geometry=""
  else
    geometry=$(slurp 2>/dev/null) || geometry=""
  fi
  
  unfreezescreen

  if [[ -z "$geometry" ]]; then
    echo "ERROR|cancelled"
    exit 0
  fi
  
  if ! grim -g "$geometry" "$FILEPATH" 2>/dev/null; then
    emit_error "grim failed to capture region"
    exit 1
  fi
}

capture_screen() {
  if [[ -n "$MONITOR" ]]; then
    if ! grim -o "$MONITOR" "$FILEPATH" 2>/dev/null; then
        # Fallback if monitor name is invalid
        grim "$FILEPATH" 2>/dev/null || { emit_error "grim failed to capture screen"; exit 1; }
    fi
  else
    grim "$FILEPATH" 2>/dev/null || { emit_error "grim failed to capture screen"; exit 1; }
  fi
}

capture_fullscreen() {
  grim "$FILEPATH" 2>/dev/null || { emit_error "grim failed to capture fullscreen"; exit 1; }
}

# Main execution
if ! command -v grim >/dev/null 2>&1; then
  emit_error "missing dependency: grim"
  exit 1
fi

ensure_output_dir

case "$MODE" in
  region|area)
    capture_region
    ;;
  screen)
    capture_screen
    ;;
  fullscreen)
    capture_fullscreen
    ;;
  *)
    emit_error "unknown mode: ${MODE}"
    exit 1
    ;;
esac

if [[ -f "$FILEPATH" ]]; then
  copy_to_clipboard
  echo "OK|${FILEPATH}"
else
  emit_error "capture failed: file not created"
  exit 1
fi
