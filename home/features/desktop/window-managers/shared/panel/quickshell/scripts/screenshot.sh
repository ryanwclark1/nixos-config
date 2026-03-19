#!/usr/bin/env bash
# Screenshot capture script for ScreenshotService
# Usage: qs-screenshot <mode> [monitor] [editor]
# Modes: region, screen, fullscreen, window, area
# Editor: none | swappy | satty

set -uo pipefail

MODE="${1:-region}"
MONITOR="${2:-}"
SCREENSHOT_EDITOR="${3:-none}"
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

capture_area() {
  local geometry="$MONITOR"
  if [[ -z "$geometry" ]]; then
    emit_error "no geometry provided for area mode"
    exit 1
  fi
  if ! grim -g "$geometry" "$FILEPATH" 2>/dev/null; then
    emit_error "grim failed to capture area"
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

capture_window() {
  local geometry=""
  if command -v hyprctl >/dev/null 2>&1; then
    geometry=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null)
  elif command -v niri >/dev/null 2>&1; then
    geometry=$(niri msg --json focused-window | jq -r '"\(.layout.tile_pos_in_workspace_view[0]),\(.layout.tile_pos_in_workspace_view[1]) \(.layout.window_size[0])x\(.layout.window_size[1])"' 2>/dev/null)
  fi
  if [[ -z "$geometry" || "$geometry" == "null" || "$geometry" == *"null"* ]]; then
    emit_error "could not determine active window geometry"
    exit 1
  fi
  grim -g "$geometry" "$FILEPATH" 2>/dev/null || { emit_error "grim failed to capture window"; exit 1; }
}

# Main execution
if ! command -v grim >/dev/null 2>&1; then
  emit_error "missing dependency: grim"
  exit 1
fi

ensure_output_dir

case "$MODE" in
  region)
    capture_region
    ;;
  area)
    capture_area
    ;;
  screen)
    capture_screen
    ;;
  fullscreen)
    capture_fullscreen
    ;;
  window)
    capture_window
    ;;
  *)
    emit_error "unknown mode: ${MODE}"
    exit 1
    ;;
esac

if [[ -f "$FILEPATH" ]]; then
  copy_to_clipboard
  # Launch editor if configured (detached so it doesn't block stdout)
  if [[ -n "${SCREENSHOT_EDITOR:-}" && "$SCREENSHOT_EDITOR" != "none" ]]; then
    case "$SCREENSHOT_EDITOR" in
      swappy) command -v swappy >/dev/null 2>&1 && swappy -f "$FILEPATH" & ;;
      satty)  command -v satty >/dev/null 2>&1 && satty --filename "$FILEPATH" & ;;
    esac
  fi
  echo "OK|${FILEPATH}"
else
  emit_error "capture failed: file not created"
  exit 1
fi
