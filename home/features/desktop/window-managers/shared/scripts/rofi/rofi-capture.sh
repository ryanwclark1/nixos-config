#!/usr/bin/env bash
set -euo pipefail

# Quick wrapper script for rofi capture menu
# Launches the capture submenu from system-menu-rofi

if ! command -v system-menu-rofi >/dev/null 2>&1; then
    notify-send "Error" "system-menu-rofi not found" 2>/dev/null || \
        echo "Error: system-menu-rofi not found" >&2
    exit 1
fi

system-menu-rofi capture
