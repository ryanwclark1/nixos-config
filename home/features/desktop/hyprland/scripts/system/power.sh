#!/usr/bin/env bash

# Power management script for wlogout integration
# Redirects to the unified power menu functionality

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

case "${1:-}" in
    "lock")
        if command -v hyprlock >/dev/null; then
            hyprlock
        elif command -v swaylock >/dev/null; then
            swaylock
        else
            notify-send "Error" "No lock screen program found"
            exit 1
        fi
        ;;
    "logout")
        hyprctl dispatch exit
        ;;
    "suspend")
        systemctl suspend
        ;;
    "reboot")
        systemctl reboot
        ;;
    "shutdown")
        systemctl poweroff
        ;;
    *)
        echo "Usage: $0 {lock|logout|suspend|reboot|shutdown}"
        exit 1
        ;;
esac