#!/usr/bin/env bash

set -euo pipefail

if (($# == 0)); then
  echo "Usage: os-cmd-present [command...]" >&2
  exit 1
fi

for cmd in "$@"; do
  command -v "$cmd" &>/dev/null || exit 1
done

exit 0
