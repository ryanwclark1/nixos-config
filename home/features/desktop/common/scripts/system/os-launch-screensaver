#!/usr/bin/env bash

set -euo pipefail

# Exit early if we don't have the tte command
if ! command -v tte &>/dev/null; then
  exit 1
fi

# Exit early if screensaver is already running
if pgrep -f org.os.screensaver >/dev/null; then
  exit 0
fi

# Allow screensaver to be turned off but also force started
if [[ -f "$HOME/.local/state/os/toggles/screensaver-off" ]] && [[ "${1:-}" != "force" ]]; then
  exit 1
fi

# Silently quit Walker on overlay
walker -q || true

focused=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true).name' | head -1 || echo "")
terminal=$(xdg-terminal-exec --print-id 2>/dev/null || echo "")

if [[ -z "$terminal" ]]; then
  notify-send "Error" "Could not determine terminal" -u critical
  exit 1
fi

monitors=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | .name' || echo "")

if [[ -z "$monitors" ]]; then
  notify-send "Error" "Could not detect monitors" -u critical
  exit 1
fi

while IFS= read -r m; do
  [[ -z "$m" ]] && continue
  hyprctl dispatch focusmonitor "$m" || true

  case "$terminal" in
    *Alacritty*)
      hyprctl dispatch exec -- \
        alacritty --class=org.os.screensaver \
        --config-file "$HOME/.local/share/os/default/alacritty/screensaver.toml" \
        -e os-cmd-screensaver
      ;;
    *ghostty*)
      hyprctl dispatch exec -- \
        ghostty --class=org.os.screensaver \
        --config-file="$HOME/.local/share/os/default/ghostty/screensaver" \
        --font-size=18 \
        -e os-cmd-screensaver
      ;;
    *kitty*)
      hyprctl dispatch exec -- \
        kitty --class=org.os.screensaver \
        --override font_size=18 \
        --override window_padding_width=0 \
        -e os-cmd-screensaver
      ;;
    *)
      notify-send "✋  Screensaver only runs in Alacritty, Ghostty, or Kitty"
      ;;
  esac
done <<<"$monitors"

if [[ -n "$focused" ]]; then
  hyprctl dispatch focusmonitor "$focused" || true
fi
