#!/usr/bin/env bash

set -euo pipefail

echo -e "Restarting pipewire audio service...\n"
systemctl --user restart pipewire.service || {
  echo "Error: Failed to restart pipewire service" >&2
  exit 1
}
