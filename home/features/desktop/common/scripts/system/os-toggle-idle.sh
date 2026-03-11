#!/usr/bin/env bash

set -euo pipefail

if pgrep -x hypridle >/dev/null; then
  pkill -x hypridle || true
  notify-send "Stop locking computer when idle"
else
  uwsm-app -- hypridle >/dev/null 2>&1 &
  notify-send "Now locking computer when idle"
fi

# Update waybar if it's running
if pgrep -x waybar >/dev/null; then
  pkill -RTMIN+9 waybar 2>/dev/null || true
fi
