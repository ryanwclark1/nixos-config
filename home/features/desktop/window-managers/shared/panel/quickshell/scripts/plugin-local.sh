#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mode="${1:-quick}"

usage() {
  cat <<'EOF'
Usage:
  plugin-local.sh [quick|full|doctor] [plugins_dir]

Modes:
  quick   Run fast local plugin guardrails (default)
  full    Run complete local plugin verification gate
  doctor  Run plugin doctor against optional plugins_dir
EOF
}

case "$mode" in
  quick)
    printf '[INFO] Local quick plugin checks...\n'
    "${script_dir}/check-plugin-runtime-guards.sh"
    "${script_dir}/check-plugin-diagnostics-contracts.sh"
    "${script_dir}/sync-plugin-diagnostics-schema.sh" --check
    "${script_dir}/check-plugin-diagnostics-schema.sh"
    printf '[INFO] Local quick plugin checks passed.\n'
    ;;
  full)
    printf '[INFO] Local full plugin checks...\n'
    "${script_dir}/plugin-verify.sh"
    ;;
  doctor)
    target="${2:-${HOME}/.config/quickshell/plugins}"
    printf '[INFO] Running plugin doctor for %s...\n' "$target"
    "${script_dir}/plugin-doctor.sh" "$target"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "[FAIL] Unknown mode: $mode" >&2
    usage >&2
    exit 2
    ;;
esac
