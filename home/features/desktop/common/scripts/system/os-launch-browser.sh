#!/usr/bin/env bash

set -euo pipefail

default_browser=$(xdg-settings get default-web-browser 2>/dev/null || echo "chromium.desktop")
browser_exec=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' ~/.local/share/applications/"$default_browser" ~/.nix-profile/share/applications/"$default_browser" /usr/share/applications/"$default_browser" 2>/dev/null | head -1)

if [[ -z "$browser_exec" ]]; then
  echo "Error: Could not find browser executable for $default_browser" >&2
  exit 1
fi

if "$browser_exec" --help 2>&1 | grep -q MOZ_LOG; then
  private_flag="--private-window"
elif [[ "$browser_exec" =~ edge ]]; then
  private_flag="--inprivate"
else
  private_flag="--incognito"
fi

exec setsid uwsm-app -- "$browser_exec" "${@/--private/$private_flag}"
