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

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    emit_error "missing dependency: ${tool}"
    exit 1
  fi
}

ensure_output_dir() {
  if ! mkdir -p "$SCREENSHOTS_DIR" 2>/dev/null; then
    emit_error "unable to create screenshots directory"
    exit 1
  fi
}

copy_to_clipboard() {
  if command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$FILEPATH" >/dev/null 2>&1 || true
  fi
}

capture_region() {
  require_tool "slurp"
  local geometry
  geometry="$(slurp 2>/dev/null)" || geometry=""
  if [[ -z "$geometry" ]]; then
    echo "ERROR|cancelled"
    exit 0
  fi
  grim -g "$geometry" "$FILEPATH"
}

capture_screen() {
  if [[ -n "$MONITOR" ]]; then
    grim -o "$MONITOR" "$FILEPATH"
  else
    grim "$FILEPATH"
  fi
}

capture_fullscreen() {
  grim "$FILEPATH"
}

require_tool "date"
require_tool "mkdir"
require_tool "grim"
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
  emit_error "capture failed"
  exit 1
fi
