#!/usr/bin/env bash

set -euo pipefail

echo -e "Unblocking wifi...\n"
rfkill unblock wifi || true
rfkill list wifi || true
