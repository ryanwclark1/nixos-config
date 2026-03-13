#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
ci_mode=0
instance_id=""

usage() {
  cat <<'EOF'
Usage: check-launcher-smoke.sh [--ci]

Runs launcher validation gates.
  default: guardrails + responsive/runtime + ipc-health + benchmarks
  --ci: guardrails + benchmarks (skips live-session runtime probes)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      instance_id="${2:-}"
      shift 2
      ;;
    --ci)
      ci_mode=1
      shift
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
done

discover_launcher_instance() {
  local runtime_root candidate show_output fallback_candidate=""
  runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
  if [[ ! -d "${runtime_root}" ]]; then
    return 1
  fi
  while IFS= read -r candidate; do
    show_output="$(quickshell ipc --id "${candidate}" show 2>/dev/null || true)"
    if [[ -z "${show_output}" ]]; then
      continue
    fi
    if ! printf '%s' "${show_output}" | rg -q "target Launcher"; then
      continue
    fi

    if [[ -z "${fallback_candidate}" ]]; then
      fallback_candidate="${candidate}"
    fi

    if printf '%s' "${show_output}" | rg -q "function drunCategoryState\\("; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done < <(find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -printf '%T@ %f\n' 2>/dev/null | sort -nr | awk '{print $2}')
  if [[ -n "${fallback_candidate}" ]]; then
    printf '%s\n' "${fallback_candidate}"
    return 0
  fi
  return 1
}

"${script_dir}/check-launcher-guardrails.sh"
if (( ci_mode == 0 )); then
  if [[ -z "${instance_id}" ]]; then
    instance_id="$(discover_launcher_instance || true)"
  fi
  if [[ -n "${instance_id}" ]]; then
    "${script_dir}/check-launcher-responsive.sh" --id "${instance_id}"
    "${script_dir}/check-launcher-ipc-health.sh" --id "${instance_id}"
  else
    "${script_dir}/check-launcher-responsive.sh"
    "${script_dir}/check-launcher-ipc-health.sh"
  fi
else
  "${script_dir}/check-launcher-responsive.sh" --ci
  "${script_dir}/check-launcher-ipc-health.sh" --ci
fi
"${script_dir}/check-launcher-benchmarks.sh"

printf '%s\n' "Launcher smoke checks passed."
