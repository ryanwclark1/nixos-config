#!/usr/bin/env bash

# -----------------------------------------------------
# Wayland Screen Recording Stop Script
# Stop any active screen recording
# -----------------------------------------------------

set -euo pipefail

if pgrep -x wl-screenrec >/dev/null || pgrep -x wf-recorder >/dev/null; then
  pkill -x wl-screenrec 2>/dev/null || true
  pkill -x wf-recorder 2>/dev/null || true
  notify-send "⏹️ Screen Recording" "Recording stopped" -t 2000
  echo "Screen recording stopped"
else
  echo "No screen recording in progress"
fi
