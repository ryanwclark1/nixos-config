#!/usr/bin/env bash

# -----------------------------------------------------
# Wayland Screen Recording Toggle Script
# Toggle screen recording on/off
# -----------------------------------------------------

set -euo pipefail

if pgrep -x wl-screenrec >/dev/null || pgrep -x wf-recorder >/dev/null; then
  # Stop recording
  exec "$(dirname "$0")/screenrecord-stop.sh"
else
  # Start recording
  exec "$(dirname "$0")/screenrecord.sh" "$@"
fi
