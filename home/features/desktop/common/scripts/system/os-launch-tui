#!/usr/bin/env bash

set -euo pipefail

if (($# == 0)); then
  echo "Usage: os-launch-tui [command] [args...]" >&2
  exit 1
fi

exec setsid uwsm-app -- xdg-terminal-exec --app-id="org.os.$(basename "$1")" -e "$1" "${@:2}"
