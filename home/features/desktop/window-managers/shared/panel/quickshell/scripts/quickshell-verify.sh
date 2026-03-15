#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

usage() {
  cat <<'EOF'
Usage: quickshell-verify.sh [--quiet]

Run the Quickshell-first live verification workflow:
  1. shared plugin/runtime guards
  2. live Quickshell startup/settings/surfaces checks
  3. panel runtime verification, including multibar when supported

This is a thin wrapper over:
  scripts/plugin-local.sh live-gates
EOF
}

quiet=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet)
      quiet=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if (( quiet == 0 )); then
  "${script_dir}/plugin-local.sh" live-gates
else
  "${script_dir}/plugin-local.sh" live-gates --quiet
fi
