#!/usr/bin/env bash
#   ____                                          _
#  / ___| __ _ _ __ ___   ___ _ __ ___   ___   __| | ___
# | |  _ / _` | '_ ` _ \ / _ \ '_ ` _ \ / _ \ / _` |/ _ \
# | |_| | (_| | | | | | |  __/ | | | | | (_) | (_| |  __/
#  \____|\__,_|_| |_| |_|\___|_| |_| |_|\___/ \__,_|\___|
#

set -euo pipefail

# Configuration
GAMEMODE_FLAG="$HOME/.config/desktop/window-managers/hyprland/scripts/settings/gamemode-enabled"

# Check required commands
if ! command -v hyprctl >/dev/null 2>&1; then
    echo "Error: hyprctl not found" >&2
    exit 1
fi

# Notification helper
notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$@"
    fi
}

# Ensure settings directory exists
mkdir -p "$(dirname "$GAMEMODE_FLAG")"

# Toggle gamemode
if [[ -f "$GAMEMODE_FLAG" ]]; then
    # Deactivate gamemode
    if hyprctl reload >/dev/null 2>&1; then
        rm -f "$GAMEMODE_FLAG"
        notify "Gamemode deactivated" "Animations and blur enabled"
    else
        echo "Error: Failed to reload Hyprland config" >&2
        exit 1
    fi
else
    # Activate gamemode
    if hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0" >/dev/null 2>&1; then
        touch "$GAMEMODE_FLAG"
        notify "Gamemode activated" "Animations and blur disabled"
    else
        echo "Error: Failed to apply gamemode settings" >&2
        exit 1
    fi
fi
