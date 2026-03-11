#!/usr/bin/env bash

set -euo pipefail

if (($# == 0)); then
  echo "Usage: os-launch-webapp [url] [additional-args...]" >&2
  exit 1
fi

browser=$(xdg-settings get default-web-browser 2>/dev/null || echo "")

case "$browser" in
  google-chrome* | brave-browser* | microsoft-edge* | opera* | vivaldi* | helium*) ;;
  *) browser="chromium.desktop" ;;
esac

browser_exec=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' ~/.local/share/applications/"$browser" ~/.nix-profile/share/applications/"$browser" /usr/share/applications/"$browser" 2>/dev/null | head -1)

if [[ -z "$browser_exec" ]]; then
  echo "Error: Could not find browser executable for $browser" >&2
  exit 1
fi

exec setsid uwsm-app -- "$browser_exec" --app="$1" "${@:2}"
