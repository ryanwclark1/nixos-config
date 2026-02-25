#!/usr/bin/env bash
# Notification hook: Send desktop notifications when Claude needs attention

set -euo pipefail

# Detect platform and send appropriate notification
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux - use notify-send
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -i "dialog-information" \
      "Claude Code" \
      "Claude Code needs your attention" \
      2>/dev/null || true
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS - use osascript
  osascript -e 'display notification "Claude Code needs your attention" with title "Claude Code"' 2>/dev/null || true
fi

exit 0
