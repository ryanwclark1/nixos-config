#!/usr/bin/env bash

SCREENSHOT_DIR="/tmp/hyprland-workspace-previews"
mkdir -p "$SCREENSHOT_DIR"

# Function to generate a list of workspaces
gen_workspaces() {
    hyprctl workspaces -j | jq -r '.[].name' | sort -n
}

if [ -z "$@" ]; then
    # Show Rofi menu
    CHOICE=$(echo -e "empty\n$(gen_workspaces)" | rofi -dmenu -p "Switch Workspace:")

    if [ -n "$CHOICE" ]; then
        # Re-run the script with the chosen workspace as argument
        "$0" "$CHOICE"
    fi
else
    WORKSPACE=$@

    if [ "$WORKSPACE" = "empty" ]; then
        # Switch to the next empty workspace
        hyprctl dispatch workspace empty
    elif [ -n "$WORKSPACE" ]; then
        # Switch to the selected workspace
        hyprctl dispatch workspace "$WORKSPACE"
    fi
fi
