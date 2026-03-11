#!/usr/bin/env bash

# -----------------------------------------------------
# MPD Control Utilities
# Shared MPD (Music Player Daemon) control functions
# -----------------------------------------------------
#
# This script provides shared utilities for controlling MPD,
# including status checking, playback control, and state management.
# -----------------------------------------------------

set -euo pipefail

# Check if MPD is available
check_mpd() {
    if ! command -v mpc >/dev/null 2>&1; then
        echo "Error: mpc (MPD client) not found" >&2
        return 1
    fi
    return 0
}

# Check if MPD is running
is_mpd_running() {
    local status
    status="$(mpc status 2>/dev/null || echo "")"
    [[ -n "$status" ]]
}

# Get MPD status
get_mpd_status() {
    mpc status 2>/dev/null || echo ""
}

# Get current song
get_mpd_current_song() {
    mpc -f "%artist% - %title%" current 2>/dev/null || echo ""
}

# Get MPD position info
get_mpd_position() {
    mpc status 2>/dev/null | grep "#" | awk '{print $3}' 2>/dev/null || echo ""
}

# Check if MPD is playing
is_mpd_playing() {
    local status
    status=$(get_mpd_status)
    [[ "$status" == *"[playing]"* ]]
}

# Check if repeat is enabled
is_mpd_repeat_on() {
    local status
    status=$(get_mpd_status)
    [[ "$status" == *"repeat: on"* ]]
}

# Check if random is enabled
is_mpd_random_on() {
    local status
    status=$(get_mpd_status)
    [[ "$status" == *"random: on"* ]]
}

# Start MPD
start_mpd() {
    if systemctl --user start mpd 2>/dev/null; then
        return 0
    fi

    # Fallback: try starting mpd directly
    if command -v mpd >/dev/null 2>&1; then
        mpd 2>/dev/null &
        return 0
    fi

    return 1
}

# Toggle play/pause
mpd_toggle() {
    mpc -q toggle 2>/dev/null
}

# Stop playback
mpd_stop() {
    mpc -q stop 2>/dev/null
}

# Previous track
mpd_prev() {
    mpc -q prev 2>/dev/null
}

# Next track
mpd_next() {
    mpc -q next 2>/dev/null
}

# Toggle repeat
mpd_repeat() {
    mpc -q repeat 2>/dev/null
}

# Toggle random
mpd_random() {
    mpc -q random 2>/dev/null
}
