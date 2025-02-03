#!/usr/bin/env bash

# Get the directory where the script is located
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default TMUX_FZF_ORDER if not set
[[ -z "$TMUX_FZF_ORDER" ]] && TMUX_FZF_ORDER="copy-mode|session|window|pane|command|keybinding|clipboard|process"

# Load environment variables
source "$CURRENT_DIR/scripts/.envs"

# Convert the order string into a list, each on a new line
items_origin="$(printf "%s" "$TMUX_FZF_ORDER" | tr '|' '\n')"

# Remove "copy-mode" if we are not in copy-mode
if [[ "$(tmux display-message -p '#{pane_in_mode}')" -eq 0 ]]; then
    items_origin="$(printf "%s\n" "$items_origin" | sed '/copy-mode/d')"
fi

# Add "menu" option if TMUX_FZF_MENU is set
if [[ -n "$TMUX_FZF_MENU" ]]; then
    items_origin+=$'\nmenu'
fi

# Append cancel option
items_origin+=$'\n[cancel]'

# Run FZF to select an item
item=$(printf "%s\n" "$items_origin" | "$TMUX_FZF_BIN" $TMUX_FZF_OPTIONS)

# Exit if the user selects "[cancel]" or no item
[[ "$item" == "[cancel]" || -z "$item" ]] && exit 0

# Execute the selected script in the background
tmux run-shell -b "$CURRENT_DIR/scripts/${item}.sh"
