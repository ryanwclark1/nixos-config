#!/usr/bin/env bash

# Smart workspace switcher (create workspace if it doesn't exist)

workspace="$1"
if [[ -z "$workspace" ]]; then
  echo "Usage: workspace-switch <workspace_number>"
  exit 1
fi

# Switch to workspace (Hyprland will create it if it doesn't exist)
hyprctl dispatch workspace "$workspace"