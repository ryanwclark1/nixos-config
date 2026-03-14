#!/usr/bin/env bash
# Screenshot capture script for ScreenshotService
# Usage: qs-screenshot <mode> [monitor]
# Modes: region, screen, fullscreen

MODE="${1:-region}"
MONITOR="${2:-}"
SCREENSHOTS_DIR="${HOME}/Pictures/Screenshots"
mkdir -p "$SCREENSHOTS_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILEPATH="${SCREENSHOTS_DIR}/screenshot_${TIMESTAMP}.png"

case "$MODE" in
  region)
    GEOMETRY=$(slurp 2>/dev/null)
    if [ -z "$GEOMETRY" ]; then
      echo "ERROR|cancelled"
      exit 0
    fi
    grim -g "$GEOMETRY" "$FILEPATH" 2>/dev/null
    ;;
  screen)
    if [ -n "$MONITOR" ]; then
      grim -o "$MONITOR" "$FILEPATH" 2>/dev/null
    else
      grim "$FILEPATH" 2>/dev/null
    fi
    ;;
  fullscreen)
    grim "$FILEPATH" 2>/dev/null
    ;;
  *)
    echo "ERROR|unknown mode: $MODE"
    exit 1
    ;;
esac

if [ -f "$FILEPATH" ]; then
  wl-copy < "$FILEPATH" 2>/dev/null
  echo "OK|${FILEPATH}"
else
  echo "ERROR|capture failed"
fi
