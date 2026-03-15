#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_root="$(CDPATH= cd -- "${script_dir}/../config" >/dev/null && pwd)"
instance_id=""
repo_shell_mode=0
repo_shell_pid=""
repo_shell_service_was_active=0
run_settings=1
run_surfaces=1
run_multibar=1

usage() {
  cat <<'EOF'
Usage: check-panel-runtime.sh [--id INSTANCE_ID] [--repo-shell] [--skip-settings] [--skip-surfaces] [--skip-multibar]

Run the shared panel runtime verification stack:
  1. panel config contract checks
  2. settings responsive smoke
  3. live popup/panel surface smoke
  4. synthetic multibar shell matrix and management harnesses

If more than one QuickShell instance is running, pass --id INSTANCE_ID.
In headless/offscreen environments, the multibar phase can end in [SKIP] results when
PanelWindow backends are unavailable; treat that as an environment limit, not a widget failure.
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
    --skip-settings)
      run_settings=0
      shift
      ;;
    --skip-surfaces)
      run_surfaces=0
      shift
      ;;
    --skip-multibar)
      run_multibar=0
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

run_step() {
  local label="$1"
  shift
  printf '[INFO] %s...\n' "$label"
  if [[ $# -gt 0 && -f "$1" && ! -x "$1" ]]; then
    bash "$@"
  else
    "$@"
  fi
}

run_ipc() {
  local output=""
  local status=0
  local attempt

  for attempt in 1 2 3 4 5; do
    output="$(timeout 5s "$@" 2>&1)" && return 0
    status=$?
    if [[ "${output}" == *"Not ready to accept queries yet."* ]]; then
      sleep 0.2
      continue
    fi
    [[ -n "${output}" ]] && printf '%s\n' "${output}" >&2
    return "${status}"
  done

  [[ -n "${output}" ]] && printf '%s\n' "${output}" >&2
  return "${status}"
}

cleanup_repo_shell() {
  if [[ -n "${repo_shell_pid}" ]]; then
    kill "${repo_shell_pid}" >/dev/null 2>&1 || true
    wait "${repo_shell_pid}" >/dev/null 2>&1 || true
  fi
  if (( repo_shell_service_was_active == 1 )); then
    systemctl --user start quickshell.service >/dev/null 2>&1 || true
  fi
}

start_repo_shell() {
  local deadline

  if ! command -v systemctl >/dev/null 2>&1; then
    printf 'systemctl is required for --repo-shell mode.\n' >&2
    exit 1
  fi

  if systemctl --user is-active --quiet quickshell.service; then
    repo_shell_service_was_active=1
    systemctl --user stop quickshell.service >/dev/null 2>&1 || true
    sleep 1
  fi

  quickshell -p "${config_root}/shell.qml" >/tmp/quickshell-repo-qa.log 2>&1 &
  repo_shell_pid="$!"

  deadline=$((SECONDS + 20))
  while (( SECONDS < deadline )); do
    if run_ipc quickshell ipc --pid "${repo_shell_pid}" show >/dev/null; then
      printf '[INFO] Repo shell instance ready: pid %s\n' "${repo_shell_pid}"
      return 0
    fi
    sleep 0.5
  done

  printf 'Repo shell did not become IPC-ready in time. See /tmp/quickshell-repo-qa.log\n' >&2
  exit 1
}

main() {
  local args=()

  if (( repo_shell_mode == 1 )); then
    trap cleanup_repo_shell EXIT
    start_repo_shell
  fi

  if [[ -n "${instance_id}" ]]; then
    args+=(--id "${instance_id}")
  fi

  if (( run_settings == 0 && run_surfaces == 0 && run_multibar == 0 )); then
    printf 'Nothing to run. Remove at least one --skip-* flag.\n' >&2
    exit 2
  fi

  run_step "Running panel config contract checks" "${script_dir}/check-panel-config-contracts.sh"

  if (( run_settings == 1 )); then
    run_step "Running settings responsive smoke" "${script_dir}/check-settings-responsive.sh" "${args[@]}"
  fi

  if (( run_surfaces == 1 )); then
    run_step "Running live surface responsive smoke" "${script_dir}/check-surface-responsive.sh" "${args[@]}"
  fi

  if (( run_multibar == 1 )); then
    run_step "Running synthetic multibar smoke" "${script_dir}/check-multibar-smoke.sh"
  fi

  printf '[INFO] Panel runtime verification completed. In headless/offscreen environments, multibar [SKIP] results can be expected. Manual visual QA is still required for final signoff.\n'
}

main "$@"
