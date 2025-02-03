#!/usr/bin/env bash

# Get the directory where the script is located
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Start copyq or cliphist if available
if command -v copyq &>/dev/null; then
  copyq &>/dev/null &
elif command -v cliphist &>/dev/null; then
  cliphist daemon &>/dev/null &
fi

# Set default keybinding if not already set
[ -z "$TMUX_FZF_LAUNCH_KEY" ] && TMUX_FZF_LAUNCH_KEY="F"

# Bind the key to launch the main script
tmux bind-key "$TMUX_FZF_LAUNCH_KEY" run-shell -b "$CURRENT_DIR/main.sh"
