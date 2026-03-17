#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

usage() {
  cat <<'EOF'
Usage: quickshell-verify.sh [--quiet]

Run the Quickshell-first verification workflow.
By default the visual/runtime phase uses the VM-backed panel QA wrappers.
  1. shared plugin/runtime guards
  2. VM-backed Quickshell runtime/settings checks
  3. host repo-shell opt-out via PLUGIN_LOCAL_QUICKSHELL_USE_VM=0 when needed

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
