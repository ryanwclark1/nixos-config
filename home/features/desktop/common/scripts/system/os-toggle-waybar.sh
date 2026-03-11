#!/usr/bin/env bash

set -euo pipefail

if pgrep -x waybar >/dev/null; then
  pkill -x waybar || true
else
  uwsm-app -- waybar >/dev/null 2>&1 &
fi
