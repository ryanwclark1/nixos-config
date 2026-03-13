#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

"${script_dir}/check-launcher-keymap.sh"
"${script_dir}/check-launcher-web-aliases.sh"
"${script_dir}/check-launcher-performance.sh"

printf '%s\n' "Launcher guardrail checks passed."
