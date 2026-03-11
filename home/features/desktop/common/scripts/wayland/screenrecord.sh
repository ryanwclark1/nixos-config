#!/usr/bin/env bash

# -----------------------------------------------------
# Wayland Screen Recording Script
# Screen recording utilities with area selection
# -----------------------------------------------------
#
# This script provides screen recording functionality for Wayland
# compositors with intelligent area selection and hardware acceleration.
# -----------------------------------------------------

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
OUTPUT_DIR="${SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}}"

# Load XDG directories configuration
if [[ -f ~/.config/user-dirs.dirs ]]; then
  source ~/.config/user-dirs.dirs
  OUTPUT_DIR="${SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}}"
fi

# Ensure output directory exists
if [[ ! -d "$OUTPUT_DIR" ]]; then
  mkdir -p "$OUTPUT_DIR" || {
    notify-send "Screen Recording Error" "Cannot create directory: $OUTPUT_DIR" -u critical -t 3000
    exit 1
  }
fi

# Function to start screen recording
start_recording() {
  local filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
  notify-send "🎬 Screen Recording" "Starting recording..." -t 1500
  sleep 1

  # Choose recorder based on graphics hardware
  if command -v lspci >/dev/null 2>&1 && lspci | grep -Eqi 'nvidia|intel.*graphics'; then
    # Use wf-recorder for better hardware acceleration support
    echo "Using wf-recorder (hardware accelerated)"
    wf-recorder -f "$filename" -c libx264 -p crf=23 -p preset=medium -p movflags=+faststart "$@"
  elif command -v wl-screenrec >/dev/null 2>&1; then
    # Use wl-screenrec as default
    echo "Using wl-screenrec"
    wl-screenrec -f "$filename" --ffmpeg-encoder-options="-c:v libx264 -crf 23 -preset medium -movflags +faststart" "$@"
  elif command -v wf-recorder >/dev/null 2>&1; then
    # Fallback to wf-recorder
    echo "Using wf-recorder (fallback)"
    wf-recorder -f "$filename" -c libx264 -p crf=23 -p preset=medium -p movflags=+faststart "$@"
  else
    notify-send "Screen Recording Error" "No screen recorder found (wl-screenrec or wf-recorder required)" -u critical -t 3000
    exit 1
  fi

  # Notify when recording stops
  if [[ -f "$filename" ]]; then
    notify-send "✅ Screen Recording" "Saved: $(basename "$filename")" -t 3000
    echo "Recording saved to: $filename"
  fi
}

# Check if recording is already in progress
if pgrep -x wl-screenrec >/dev/null || pgrep -x wf-recorder >/dev/null; then
  # Stop existing recording
  pkill -x wl-screenrec 2>/dev/null || true
  pkill -x wf-recorder 2>/dev/null || true
  notify-send "⏹️ Screen Recording" "Recording stopped" -t 2000
  exit 0
fi

# Start recording based on argument
case "${1:-region}" in
  "output"|"fullscreen")
    echo "Recording full screen"
    start_recording
    ;;
  "region"|*)
    echo "Recording selected region"
    if ! command -v slurp >/dev/null 2>&1; then
      notify-send "Screen Recording Error" "slurp not found (required for region selection)" -u critical -t 3000
      exit 1
    fi
    region=$(slurp 2>/dev/null) || {
      notify-send "Screen Recording" "Region selection cancelled" -t 1000
      exit 1
    }
    start_recording -g "$region"
    ;;
esac
