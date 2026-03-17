#!/usr/bin/env bash

set -euo pipefail

omarchy-state clear re*-required || true

# Schedule the reboot to happen after closing windows (detached from terminal)
nohup bash -c "sleep 2 && systemctl reboot --no-wall" >/dev/null 2>&1 &

# Now close all windows
close-all-windows || true
sleep 1 # Allow apps like Chrome to shutdown correctly
