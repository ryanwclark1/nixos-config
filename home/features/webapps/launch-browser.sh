#!/usr/bin/env bash

# Smart browser launcher with fallback chain
# Finds and launches the default browser with proper error handling

set -euo pipefail

# Get the default web browser from xdg-settings
default_browser=$(xdg-settings get default-web-browser 2>/dev/null || echo "")

if [[ -n "$default_browser" ]]; then
  # Find the executable from the desktop file
  for app_dir in ~/.local/share/applications ~/.nix-profile/share/applications /run/current-system/sw/share/applications; do
    desktop_file="$app_dir/$default_browser"
    if [[ -f "$desktop_file" ]]; then
      exec_line=$(grep "^Exec=" "$desktop_file" | head -1)
      if [[ -n "$exec_line" ]]; then
        # Extract the executable name (first word after Exec=)
        browser_exec=$(echo "$exec_line" | sed -n 's/^Exec=\([^ ]*\).*/\1/p')
        if [[ -n "$browser_exec" ]]; then
          echo "Launching default browser: $browser_exec"
          exec "$browser_exec" "$@" &
          exit 0
        fi
      fi
    fi
  done
fi

# Fallback: try common browsers in order of preference
browsers=(firefox chromium chrome google-chrome-stable brave-browser vivaldi opera)

for browser in "${browsers[@]}"; do
  if command -v "$browser" >/dev/null 2>&1; then
    echo "Launching fallback browser: $browser"
    exec "$browser" "$@" &
    exit 0
  fi
done

echo "No web browser found!"
if command -v notify-send >/dev/null 2>&1; then
  notify-send "Browser Error" "No web browser found" -u critical
fi
exit 1