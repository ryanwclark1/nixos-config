#!/usr/bin/env bash

# Get current working directory of active terminal

# Get the PID of the currently active window
terminal_pid=$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty' 2>/dev/null)

if [[ -z "$terminal_pid" || "$terminal_pid" == "null" ]]; then
  # Fallback: try the old method without JSON
  terminal_pid=$(hyprctl activewindow 2>/dev/null | awk '/pid:/ {print $2}' | head -n1)
fi

if [[ -n "$terminal_pid" && "$terminal_pid" != "null" ]]; then
  # Find child shell process of the terminal
  shell_pid=$(pgrep -P "$terminal_pid" | head -n1)
  
  if [[ -n "$shell_pid" ]]; then
    # Get the current working directory of the shell process
    if cwd=$(readlink -f "/proc/$shell_pid/cwd" 2>/dev/null); then
      echo "$cwd"
    else
      echo "$HOME"
    fi
  else
    echo "$HOME"
  fi
else
  echo "$HOME"
fi