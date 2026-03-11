#!/usr/bin/env bash

set -euo pipefail

if (($# == 0)); then
  echo "Usage: os-restart-app [app-name] [app-args...]" >&2
  exit 1
fi

pkill -x "$1" || true
setsid uwsm-app -- "$@" >/dev/null 2>&1 &
