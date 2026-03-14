#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ "${1:-}" == "--quiet" ]]; then
  "${script_dir}/plugin-local.sh" all-gates --quiet
else
  "${script_dir}/plugin-local.sh" all-gates
fi
