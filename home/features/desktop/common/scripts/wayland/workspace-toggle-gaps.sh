#!/usr/bin/env bash

# Toggle workspace gaps on/off for the currently active workspace

workspace_id=$(hyprctl activeworkspace -j | jq -r .id)
gaps=$(hyprctl workspacerules -j | jq -r ".[] | select(.workspaceString==\"$workspace_id\") | .gapsOut[0] // 0")

if [[ $gaps == "0" ]]; then
  hyprctl keyword "workspace $workspace_id, gapsout:10, gapsin:5, bordersize:2"
  notify-send "Gaps Enabled" "Workspace $workspace_id gaps enabled"
else
  hyprctl keyword "workspace $workspace_id, gapsout:0, gapsin:0, bordersize:0"
  notify-send "Gaps Disabled" "Workspace $workspace_id gaps disabled"
fi
