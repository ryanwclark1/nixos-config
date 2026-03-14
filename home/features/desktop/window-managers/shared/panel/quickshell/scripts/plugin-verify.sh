#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "--quiet" ]]; then
  "${script_dir}/plugin-local.sh" all-gates --quiet
else
  "${script_dir}/plugin-local.sh" all-gates
fi
