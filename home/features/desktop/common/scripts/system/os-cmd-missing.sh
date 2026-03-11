#!/usr/bin/env bash

set -euo pipefail

if (($# == 0)); then
  echo "Usage: os-cmd-missing [command...]" >&2
  exit 1
fi

for cmd in "$@"; do
  if ! command -v "$cmd" &>/dev/null; then
    exit 0
  fi
done

exit 1
