#!/usr/bin/env bash

set -euo pipefail

rfkill unblock bluetooth || true
exec os-launch-or-focus-tui bluetui
