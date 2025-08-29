#!/usr/bin/env bash
# __        ______    _____             _
# \ \      / /  _ \  | ____|_ __   __ _(_)_ __   ___
#  \ \ /\ / /| |_) | |  _| | '_ \ / _` | | '_ \ / _ \
#   \ V  V / |  __/  | |___| | | | (_| | | | | |  __/
#    \_/\_/  |_|     |_____|_| |_|\__, |_|_| |_|\___|
#                                 |___/
#

# Initialize wallpaper engine with swww support
echo ":: Initializing wallpaper engine"

# Start swww daemon if available
if command -v swww >/dev/null; then
    echo ":: Starting swww daemon"
    # Kill any existing daemon first
    pkill swww-daemon 2>/dev/null || true
    sleep 0.5
    # Start with conservative settings to reduce buffer errors
    SWWW_TRANSITION_FPS=30 SWWW_TRANSITION_DURATION=1 swww-daemon &
    sleep 2
fi

# Restore wallpaper (try multiple locations)
if [[ -f ~/.config/hypr/scripts/hypr/wallpaper-manager.sh ]]; then
    ~/.config/hypr/scripts/hypr/wallpaper-manager.sh restore
elif [[ -f ~/.config/niri/scripts/wallpaper-manager.sh ]]; then
    ~/.config/niri/scripts/wallpaper-manager.sh restore
else
    echo ":: No wallpaper manager found, skipping restore"
fi
