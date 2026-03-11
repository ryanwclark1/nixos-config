#!/usr/bin/env bash

set -euo pipefail

if (($# == 0)); then
  echo "Usage: os-launch-or-focus-tui [app-name]" >&2
  exit 1
fi

APP_ID="org.os.$(basename "$1")"
LAUNCH_COMMAND="os-launch-tui $*"

exec os-launch-or-focus "$APP_ID" "$LAUNCH_COMMAND"
