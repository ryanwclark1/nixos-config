#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

"${script_dir}/check-launcher-guardrails.sh"
"${script_dir}/check-launcher-benchmarks.sh"

printf '%s\n' "Launcher smoke checks passed."
