#!/usr/bin/env bash

# Toggle hypridle daemon on/off

if pgrep -x hypridle >/dev/null; then
  pkill -x hypridle
  notify-send "🔓 Idle Disabled" "Computer will not lock when idle"
else
  uwsm app -- hypridle >/dev/null 2>&1 &
  notify-send "🔒 Idle Enabled" "Computer will lock when idle"
fi
