#!/usr/bin/env bash

set -euo pipefail

if (($# == 0)); then
  echo "Usage: os-launch-or-focus [window-pattern] [launch-command]" >&2
  exit 1
fi

WINDOW_PATTERN="$1"
LAUNCH_COMMAND="${2:-uwsm-app -- "$WINDOW_PATTERN"}"
WINDOW_ADDRESS=$(hyprctl clients -j 2>/dev/null | jq -r --arg p "$WINDOW_PATTERN" '.[]|select((.class|test("\\b" + $p + "\\b";"i")) or (.title|test("\\b" + $p + "\\b";"i")))|.address' | head -n1 || echo "")

if [[ -n "$WINDOW_ADDRESS" ]]; then
  hyprctl dispatch focuswindow "address:$WINDOW_ADDRESS"
else
  exec setsid bash -c "$LAUNCH_COMMAND"
fi
