#!/usr/bin/env bash

SCREENSHOT_DIR="/tmp/hyprland-workspace-previews"
mkdir -p "$SCREENSHOT_DIR"

# Function to capture a screenshot of a workspace
capture_screenshot() {
  local workspace=$1
  hyprctl dispatch workspace "$workspace"
  grim "$SCREENSHOT_DIR/workspace_$workspace.png"
}

# Function to list workspaces and take screenshots
gen_workspaces() {
  for workspace in $(hyprctl workspaces -j | jq -r '.[].name'); do
      if [[ ! -f "$SCREENSHOT_DIR/workspace_$workspace.png" ]]; then
          capture_screenshot "$workspace"
      fi
      echo -en "$workspace\x00icon\x1f$SCREENSHOT_DIR/workspace_$workspace.png\n"
  done
}

# Show Rofi menu with workspace previews
CHOICE=$(
  gen_workspaces | rofi -dmenu -p "Switch Workspace:" -show-icons -columns 6 -width 400 -lines 3 -flow "horizontal" -location 1 -xoffset 0 -yoffset 0 -padding 10 -font "JetBrains Mono 12" -hide-scrollbar
)

# Process user selection
if [[ -n "$CHOICE" ]]; then
  hyprctl dispatch workspace "$CHOICE"
fi