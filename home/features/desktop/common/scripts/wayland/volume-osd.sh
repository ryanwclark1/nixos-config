#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"

case "$action" in
  up)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
    wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
    ;;
  down)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    ;;
  mute)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    ;;
  *)
    echo "Usage: $0 [up|down|mute]" >&2
    exit 1
    ;;
esac

if command -v quickshell >/dev/null 2>&1; then
  state="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
  percent="$(awk '/Volume:/ { print int($2 * 100) }' <<<"$state")"
  muted="false"
  if grep -q '\[MUTED\]' <<<"$state"; then
    muted="true"
  fi
  quickshell ipc call Osd showVolume "${percent:-0}" "$muted" >/dev/null 2>&1 || true
fi
