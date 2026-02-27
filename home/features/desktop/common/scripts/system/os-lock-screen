#!/usr/bin/env bash

set -euo pipefail

# Lock the screen
if ! pgrep -x hyprlock >/dev/null; then
  hyprlock &
fi

# Set keyboard layout to default (first layout)
hyprctl switchxkblayout all 0 >/dev/null 2>&1 || true

# Ensure 1password is locked
if pgrep -x "1password" >/dev/null; then
  1password --lock &
fi

# Avoid running screensaver when locked
pkill -f org.os.screensaver || true
