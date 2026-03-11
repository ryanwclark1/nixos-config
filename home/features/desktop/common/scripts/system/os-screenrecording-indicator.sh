#!/usr/bin/env bash

set -euo pipefail

# Screen recording indicator for Waybar
# Returns JSON output indicating if screen recording is active
# Supports both gpu-screen-recorder and wl-screenrec/wf-recorder

if pgrep -f "^gpu-screen-recorder" >/dev/null || \
   pgrep -x wl-screenrec >/dev/null || \
   pgrep -x wf-recorder >/dev/null; then
  echo '{"text": "󰻂", "tooltip": "Stop recording", "class": "active"}'
else
  echo '{"text": ""}'
fi

