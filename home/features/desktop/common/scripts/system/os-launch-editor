#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${EDITOR:-}" ]] || ! os-cmd-present "$EDITOR"; then
  EDITOR=nvim
fi

case "$EDITOR" in
  nvim | vim | nano | micro | hx | helix)
    exec os-launch-tui "$EDITOR" "$@"
    ;;
  *)
    exec setsid uwsm-app -- "$EDITOR" "$@"
    ;;
esac
