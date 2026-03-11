#!/usr/bin/env bash

set -euo pipefail

cmd="$*"
exec setsid uwsm-app -- xdg-terminal-exec --app-id=org.os.terminal --title=OS -e bash -c "os-show-logo; $cmd; if (( \$? != 130 )); then os-show-done; fi"
