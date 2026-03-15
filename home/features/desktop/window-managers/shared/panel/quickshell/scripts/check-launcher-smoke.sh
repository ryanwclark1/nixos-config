#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
ci_mode=0
instance_id=""
repo_shell_mode=0
expected_config="$(realpath "${script_dir}/../config/shell.qml" 2>/dev/null || printf '%s' "${script_dir}/../config/shell.qml")"

usage() {
  cat <<'EOF'
Usage: check-launcher-smoke.sh [--id INSTANCE_ID] [--repo-shell] [--ci]

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
    --repo-shell)
      repo_shell_mode=1
      shift
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
  local runtime_root candidate show_output log_file launch_line
  local fallback_candidate="" drun_candidate="" escape_candidate="" config_candidate="" preferred_candidate=""
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

    if printf '%s' "${show_output}" | rg -q "function drunCategoryState\\(" && [[ -z "${drun_candidate}" ]]; then
      drun_candidate="${candidate}"
    fi

    if printf '%s' "${show_output}" | rg -q "function escapeActionState\\(" && [[ -z "${escape_candidate}" ]]; then
      escape_candidate="${candidate}"
    fi

    log_file="${runtime_root}/${candidate}/log.log"
    launch_line="$(sed -n '1,6p' "${log_file}" 2>/dev/null | rg -m1 "Launching config:" || true)"
    if [[ -n "${launch_line}" ]] && printf '%s' "${launch_line}" | rg -q -F -- "${expected_config}"; then
      if [[ -z "${config_candidate}" ]]; then
        config_candidate="${candidate}"
      fi
      if printf '%s' "${show_output}" | rg -q "function drunCategoryState\\(" && printf '%s' "${show_output}" | rg -q "function escapeActionState\\("; then
        preferred_candidate="${candidate}"
        break
      fi
    fi
  done < <(find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -printf '%T@ %f\n' 2>/dev/null | sort -nr | awk '{print $2}')
  if [[ -n "${preferred_candidate}" ]]; then
    printf '%s\n' "${preferred_candidate}"
    return 0
  fi
  if [[ -n "${config_candidate}" ]]; then
    printf '%s\n' "${config_candidate}"
    return 0
  fi
  if [[ -n "${drun_candidate}" ]]; then
    printf '%s\n' "${drun_candidate}"
    return 0
  fi
  if [[ -n "${escape_candidate}" ]]; then
    printf '%s\n' "${escape_candidate}"
    return 0
  fi
  if [[ -n "${fallback_candidate}" ]]; then
    printf '%s\n' "${fallback_candidate}"
    return 0
  fi
  return 1
}

"${script_dir}/check-launcher-guardrails.sh"
if (( ci_mode == 0 )); then
  if (( repo_shell_mode == 0 )) && [[ -z "${instance_id}" ]]; then
    instance_id="$(discover_launcher_instance || true)"
  fi
  if (( repo_shell_mode == 1 )); then
    "${script_dir}/check-launcher-responsive.sh" --repo-shell
    "${script_dir}/check-launcher-ipc-health.sh" --repo-shell
  elif [[ -n "${instance_id}" ]]; then
    "${script_dir}/check-launcher-responsive.sh" --id "${instance_id}"
    "${script_dir}/check-launcher-ipc-health.sh" --id "${instance_id}"
  else
    printf '%s\n' "[WARN] No reachable launcher instance found; falling back to static launcher probes and skipping live category/Esc diagnostics." >&2
    "${script_dir}/check-launcher-responsive.sh" --ci
    "${script_dir}/check-launcher-ipc-health.sh" --ci
  fi
else
  "${script_dir}/check-launcher-responsive.sh" --ci
  "${script_dir}/check-launcher-ipc-health.sh" --ci
fi
"${script_dir}/check-launcher-benchmarks.sh"

printf '%s\n' "Launcher smoke checks passed."
