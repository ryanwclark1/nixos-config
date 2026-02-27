#!/usr/bin/env bash

set -euo pipefail

if (($# < 1)); then
  echo "Usage: os-hook [name] [args...]" >&2
  exit 1
fi

HOOK="$1"
HOOK_PATH="$HOME/.config/os/hooks/$1"
shift

if [[ -f "$HOOK_PATH" ]]; then
  bash "$HOOK_PATH" "$@"
fi
