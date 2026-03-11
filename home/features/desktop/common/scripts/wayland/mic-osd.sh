#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"

case "$action" in
  up)
    wpctl set-volume -l 1 @DEFAULT_AUDIO_SOURCE@ 5%+
    ;;
  down)
    wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-
    ;;
  mute)
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    ;;
  *)
    echo "Usage: $0 [up|down|mute]" >&2
    exit 1
    ;;
esac

if command -v quickshell >/dev/null 2>&1; then
  state="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || true)"
  percent="$(awk '/Volume:/ { print int($2 * 100) }' <<<"$state")"
  muted="false"
  if grep -q '\[MUTED\]' <<<"$state"; then
    muted="true"
  fi
  quickshell ipc call Osd showMic "${percent:-0}" "$muted" >/dev/null 2>&1 || true
fi
