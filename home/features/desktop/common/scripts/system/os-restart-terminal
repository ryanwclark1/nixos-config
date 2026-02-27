#!/usr/bin/env bash

set -euo pipefail

if [[ -f "$HOME/.config/alacritty/alacritty.toml" ]]; then
  touch "$HOME/.config/alacritty/alacritty.toml"
fi

if pgrep -x kitty >/dev/null; then
  killall -SIGUSR1 kitty || true
fi

if pgrep -x ghostty >/dev/null; then
  killall -SIGUSR2 ghostty || true
fi
