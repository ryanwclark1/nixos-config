#!/usr/bin/env bash

set -euo pipefail

echo -e "Unblocking bluetooth...\n"
rfkill unblock bluetooth || true
rfkill list bluetooth || true
