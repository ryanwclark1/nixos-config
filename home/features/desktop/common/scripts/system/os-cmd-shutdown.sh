#!/usr/bin/env bash

set -euo pipefail

os-state clear re*-required || true

# Schedule the shutdown to happen after closing windows (detached from terminal)
nohup bash -c "sleep 2 && systemctl poweroff --no-wall" >/dev/null 2>&1 &

# Now close all windows
os-hyprland-window-close-all || true
sleep 1 # Allow apps like Chrome to shutdown correctly
