#!/usr/bin/env bash

set -euo pipefail

if (($# == 0)); then
  echo "Usage: os-cmd-share [clipboard|file|folder] [files...]" >&2
  exit 1
fi

MODE="$1"
shift

if [[ "$MODE" == "clipboard" ]]; then
  TEMP_FILE=$(mktemp --suffix=.txt)
  wl-paste >"$TEMP_FILE" || {
    echo "Error: Failed to read clipboard" >&2
    exit 1
  }
  # Note: Temporary file will remain until system cleanup for clipboard mode
  # This ensures the file content is available for the detached LocalSend process
  FILES="$TEMP_FILE"
else
  if (($# > 0)); then
    FILES="$*"
  else
    if [[ "$MODE" == "folder" ]]; then
      # Pick a single folder from home directory
      FILES=$(find "$HOME" -type d 2>/dev/null | fzf || true)
    else
      # Pick one or more files from home directory
      FILES=$(find "$HOME" -type f 2>/dev/null | fzf --multi || true)
    fi
    [[ -z "$FILES" ]] && exit 0
  fi
fi

# Run LocalSend in its own systemd service (detached from terminal)
# Convert newline-separated files to space-separated arguments
if [[ "$MODE" != "clipboard" ]] && echo "$FILES" | grep -q $'\n'; then
  # Multiple files selected - convert newlines to array
  readarray -t FILE_ARRAY <<<"$FILES"
  systemd-run --user --quiet --collect localsend --headless send "${FILE_ARRAY[@]}" || {
    echo "Error: Failed to start LocalSend" >&2
    exit 1
  }
else
  # Single file or clipboard mode
  systemd-run --user --quiet --collect localsend --headless send "$FILES" || {
    echo "Error: Failed to start LocalSend" >&2
    exit 1
  }
fi
