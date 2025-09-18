#!/usr/bin/env bash
# Memory monitoring module for tmux-forceline
# Provides memory usage format variables for tmux

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Memory format variables
memory_interpolation=(
    "\#{memory_percentage}"
    "\#{memory_usage}"
    "\#{memory_total}"
    "\#{ram_percentage}"
    "\#{ram_usage}"
    "\#{ram_total}"
)

memory_commands=(
    "#($CURRENT_DIR/scripts/memory_percentage.sh)"
    "#($CURRENT_DIR/scripts/memory_usage.sh)"
    "#($CURRENT_DIR/scripts/memory_total.sh)"
    "#($CURRENT_DIR/scripts/memory_percentage.sh)"
    "#($CURRENT_DIR/scripts/memory_usage.sh)"
    "#($CURRENT_DIR/scripts/memory_total.sh)"
)

# Register format variables with tmux
for ((i=0; i<${#memory_interpolation[@]}; i++)); do
    tmux set-option -gq "${memory_interpolation[$i]}" "${memory_commands[$i]}"
done