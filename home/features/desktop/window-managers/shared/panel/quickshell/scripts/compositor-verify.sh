#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mode="local"

if [[ "${1:-}" == "--ci" ]]; then
  mode="ci"
fi

printf '[INFO] Running compositor guard checks...\n'
"${script_dir}/check-compositor-guards.sh"

printf '[INFO] Running compositor fixture checks...\n'
"${script_dir}/check-compositor-fixtures.sh"

if [[ "${mode}" == "ci" ]]; then
  printf '[INFO] CI mode: skipping runtime compositor smoke checks.\n'
  exit 0
fi

printf '[INFO] Running runtime compositor smoke checks...\n'
"${script_dir}/compositor-smoke.sh"
