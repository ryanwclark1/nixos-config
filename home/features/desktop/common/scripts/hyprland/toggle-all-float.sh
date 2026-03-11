#!/usr/bin/env bash
#     _    _ _  __ _             _
#    / \  | | |/ _| | ___   __ _| |_
#   / _ \ | | | |_| |/ _ \ / _` | __|
#  / ___ \| | |  _| | (_) | (_| | |_
# /_/   \_\_|_|_| |_|\___/ \__,_|\__|
#

set -euo pipefail

# Check required commands
if ! command -v hyprctl >/dev/null 2>&1; then
    echo "Error: hyprctl not found" >&2
    exit 1
fi

# Toggle workspace floating/tiling
if hyprctl dispatch workspaceopt allfloat >/dev/null 2>&1; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Windows on this workspace toggled to floating/tiling"
    fi
else
    echo "Error: Failed to toggle workspace floating/tiling" >&2
    exit 1
fi
