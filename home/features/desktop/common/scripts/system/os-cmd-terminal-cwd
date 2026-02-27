#!/usr/bin/env bash

set -euo pipefail

# Go from current active terminal to its child shell process and run cwd there
terminal_pid=$(hyprctl activewindow 2>/dev/null | awk '/pid:/ {print $2}' || echo "")

if [[ -z "$terminal_pid" ]]; then
  echo "$HOME"
  exit 0
fi

shell_pid=$(pgrep -P "$terminal_pid" 2>/dev/null | tail -n1 || echo "")

if [[ -n "$shell_pid" ]]; then
  cwd=$(readlink -f "/proc/$shell_pid/cwd" 2>/dev/null || echo "")
  shell=$(readlink -f "/proc/$shell_pid/exe" 2>/dev/null || echo "")

  # Check if $shell is a valid shell and $cwd is a directory.
  if [[ -n "$shell" ]] && grep -qs "$shell" /etc/shells 2>/dev/null && [[ -d "$cwd" ]]; then
    echo "$cwd"
  else
    echo "$HOME"
  fi
else
  echo "$HOME"
fi
