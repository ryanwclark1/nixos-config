#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_root="$(CDPATH= cd -- "${script_dir}/../src" >/dev/null && pwd)"
runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
runtime_pid_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid"
instance_id=""
repo_shell_mode=0
repo_shell_pid=""
repo_shell_service_was_active=0
repo_shell_health_was_active=0
repo_shell_env=()
run_settings=1
run_surfaces=1
run_multibar=1
run_launcher=1
repo_shell_ready_timeout_sec="${QS_REPO_SHELL_READY_TIMEOUT_SEC:-40}"
settings_timeout_seconds="${QS_VERIFY_SETTINGS_TIMEOUT_SECONDS:-150}"
surfaces_timeout_seconds="${QS_VERIFY_SURFACES_TIMEOUT_SECONDS:-150}"
warnings_timeout_seconds="${QS_VERIFY_WARNINGS_TIMEOUT_SECONDS:-900}"
multibar_timeout_seconds="${QS_VERIFY_MULTIBAR_TIMEOUT_SECONDS:-120}"

source "${script_dir}/graphics-session-env.sh"

usage() {
  cat <<'EOF'
Usage: check-panel-runtime.sh [--id INSTANCE_ID] [--repo-shell] [--skip-settings] [--skip-surfaces] [--skip-multibar] [--skip-launcher]

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
    --skip-launcher)
      run_launcher=0
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

run_step_timeout() {
  local label="$1"
  local timeout_seconds="$2"
  shift 2
  printf '[INFO] %s...\n' "$label"
  if command -v timeout >/dev/null 2>&1; then
    if [[ $# -gt 0 && -f "$1" && ! -x "$1" ]]; then
      timeout --foreground --signal=TERM --kill-after=10s "${timeout_seconds}s" bash "$@"
    else
      timeout --foreground --signal=TERM --kill-after=10s "${timeout_seconds}s" "$@"
    fi
  else
    if [[ $# -gt 0 && -f "$1" && ! -x "$1" ]]; then
      bash "$@"
    else
      "$@"
    fi
  fi
}

run_ipc() {
  local output=""
  local status=0
  local attempt

  for attempt in 1 2 3 4 5; do
    output="$(timeout 5s "$@" 2>&1)" && return 0
    status=$?
    if [[ "${output}" == *"Not ready to accept queries yet."* ]] \
      || [[ "${output}" == *"No instance found for pid "* ]] \
      || [[ "${output}" == *"No running instances start with "* ]]; then
      sleep 0.2
      continue
    fi
    [[ -n "${output}" ]] && printf '%s\n' "${output}" >&2
    return "${status}"
  done

  [[ -n "${output}" ]] && printf '%s\n' "${output}" >&2
  return "${status}"
}

discover_instances() {
  local service_pid=""
  local resolved=""
  local dir
  local pid

  if [[ -d "${runtime_pid_root}" ]]; then
    while IFS= read -r pid; do
      [[ "${pid}" =~ ^[0-9]+$ ]] || continue
      resolved="$(readlink -f "${runtime_pid_root}/${pid}" 2>/dev/null || true)"
      if [[ -n "${resolved}" && -S "${resolved}/ipc.sock" ]]; then
        basename "${resolved}"
      fi
    done < <(
      {
        find "${runtime_pid_root}" -mindepth 1 -maxdepth 1 -type l -printf '%f\n' 2>/dev/null || true
        ps -eo pid=,comm= | awk '$2 ~ /quickshell|\\.quickshell-wra/ { print $1 }'
      } | awk 'NF && !seen[$0]++'
    )
  fi

  if command -v systemctl >/dev/null 2>&1; then
    service_pid="$(systemctl --user show quickshell.service --property MainPID --value 2>/dev/null || true)"
    if [[ "${service_pid}" =~ ^[0-9]+$ ]] && [[ "${service_pid}" != "0" ]]; then
      resolved="$(readlink -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid/${service_pid}" 2>/dev/null || true)"
      if [[ -n "${resolved}" && -S "${resolved}/ipc.sock" ]]; then
        basename "${resolved}"
        return 0
      fi
    fi
  fi

  if [[ ! -d "${runtime_root}" ]]; then
    return 0
  fi

  while IFS= read -r dir; do
    basename "${dir}"
  done < <(find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk '{print $2}')
}

discover_reachable_instance() {
  local candidate

  while IFS= read -r candidate; do
    [[ -n "${candidate}" ]] || continue
    if run_ipc quickshell ipc --id "${candidate}" show >/dev/null; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done < <(discover_instances)

  return 1
}

refresh_instance_args() {
  local refreshed_id=""
  local resolved=""

  if (( repo_shell_mode == 1 )); then
    if [[ -z "${repo_shell_pid}" ]]; then
      printf 'Repo-shell mode expected a tracked QuickShell pid, but none was recorded.\n' >&2
      return 1
    fi
    if ! run_ipc quickshell ipc --pid "${repo_shell_pid}" show >/dev/null; then
      printf 'Repo-shell pid %s is no longer reachable.\n' "${repo_shell_pid}" >&2
      return 1
    fi
    resolved="$(readlink -f "${runtime_pid_root}/${repo_shell_pid}" 2>/dev/null || true)"
    if [[ -z "${resolved}" || ! -S "${resolved}/ipc.sock" ]]; then
      printf 'Repo-shell pid %s no longer has a live runtime directory.\n' "${repo_shell_pid}" >&2
      return 1
    fi
    refreshed_id="$(basename "${resolved}")"
    if [[ -z "${instance_id}" || "${refreshed_id}" != "${instance_id}" ]]; then
      printf '[INFO] Refreshing repo-shell instance id %s -> %s\n' "${instance_id:-<unset>}" "${refreshed_id}"
      instance_id="${refreshed_id}"
    fi
    return 0
  fi

  if [[ -z "${instance_id}" ]]; then
    refreshed_id="$(discover_reachable_instance || true)"
    if [[ -n "${refreshed_id}" ]]; then
      printf '[INFO] Using discovered QuickShell instance %s\n' "${refreshed_id}"
      instance_id="${refreshed_id}"
    fi
    return 0
  fi

  if run_ipc quickshell ipc --id "${instance_id}" show >/dev/null; then
    return 0
  fi

  refreshed_id="$(discover_reachable_instance || true)"
  if [[ -z "${refreshed_id}" ]]; then
    printf 'Unable to rediscover a live QuickShell instance after reload.\n' >&2
    return 1
  fi

  if [[ "${refreshed_id}" != "${instance_id}" ]]; then
    printf '[INFO] Refreshing stale instance id %s -> %s\n' "${instance_id}" "${refreshed_id}"
    instance_id="${refreshed_id}"
  fi

  return 0
}

cleanup_repo_shell() {
  if [[ -n "${repo_shell_pid}" ]]; then
    kill "${repo_shell_pid}" >/dev/null 2>&1 || true
    wait "${repo_shell_pid}" >/dev/null 2>&1 || true
  fi
  if (( repo_shell_service_was_active == 1 )); then
    systemctl --user start quickshell.service >/dev/null 2>&1 || true
  fi
  if (( repo_shell_health_was_active == 1 )); then
    systemctl --user start quickshell-health.service >/dev/null 2>&1 || true
  fi
}

handle_termination() {
  trap - EXIT TERM INT
  cleanup_repo_shell
  exit 124
}

populate_repo_shell_env() {
  build_repo_shell_env_array repo_shell_env "QS_DISABLE_NOTIFICATION_SERVER=1"
}

start_repo_shell() {
  local deadline
  local resolved=""
  local runtime_id=""
  local stop_repo_units=0

  if ! command -v systemctl >/dev/null 2>&1; then
    printf 'systemctl is required for --repo-shell mode.\n' >&2
    exit 1
  fi

  if systemctl --user is-active --quiet quickshell.service; then
    repo_shell_service_was_active=1
    stop_repo_units=1
  fi
  if systemctl --user is-active --quiet quickshell-health.service; then
    repo_shell_health_was_active=1
    stop_repo_units=1
  fi
  if (( stop_repo_units == 1 )); then
    systemctl --user stop quickshell.service quickshell-health.service >/dev/null 2>&1 || true
    sleep 1
  fi

  pkill -x quickshell >/dev/null 2>&1 || true
  sleep 0.5

  populate_repo_shell_env
  env "${repo_shell_env[@]}" quickshell -p "${config_root}/shell.qml" >/tmp/quickshell-repo-qa.log 2>&1 &
  repo_shell_pid="$!"

  deadline=$((SECONDS + repo_shell_ready_timeout_sec))
  while (( SECONDS < deadline )); do
    resolved="$(readlink -f "${runtime_pid_root}/${repo_shell_pid}" 2>/dev/null || true)"
    runtime_id=""
    if [[ -n "${resolved}" && -S "${resolved}/ipc.sock" ]]; then
      runtime_id="$(basename "${resolved}")"
    fi
    if [[ -n "${runtime_id}" ]] && run_ipc quickshell ipc --id "${runtime_id}" show >/dev/null; then
      sleep 1
      instance_id="${runtime_id}"
      printf '[INFO] Repo shell instance ready: pid %s id %s\n' "${repo_shell_pid}" "${instance_id}"
      return 0
    fi
    sleep 0.5
  done

  printf 'Repo shell did not become IPC-ready in time after %ss. See /tmp/quickshell-repo-qa.log\n' "${repo_shell_ready_timeout_sec}" >&2
  sed -n '1,200p' /tmp/quickshell-repo-qa.log >&2 || true
  exit 1
}

main() {
  local args=()

  load_graphics_session_env

  if (( repo_shell_mode == 1 )); then
    trap cleanup_repo_shell EXIT
    trap handle_termination TERM INT
    start_repo_shell
  fi

  if [[ -n "${instance_id}" ]]; then
    args+=(--id "${instance_id}")
  fi

  if (( run_settings == 0 && run_surfaces == 0 && run_multibar == 0 && run_launcher == 0 )); then
    printf 'Nothing to run. Remove at least one --skip-* flag.\n' >&2
    exit 2
  fi

  run_step "Running panel config contract checks" "${script_dir}/check-panel-config-contracts.sh"
  run_step "Running hidden bar widget collapse checks" "${script_dir}/check-bar-widget-collapse.sh"
  run_step "Running vertical bar width checks" "${script_dir}/check-vertical-bar-width.sh"

  if (( run_settings == 1 )); then
    refresh_instance_args
    args=()
    if (( repo_shell_mode == 1 )) && [[ -n "${repo_shell_pid}" ]]; then
      args+=(--pid "${repo_shell_pid}")
    elif [[ -n "${instance_id}" ]]; then
      args+=(--id "${instance_id}")
    fi
    run_step_timeout "Running settings responsive smoke" "${settings_timeout_seconds}" "${script_dir}/check-settings-responsive.sh" "${args[@]}"
    refresh_instance_args
    run_step_timeout "Running SSH widget settings smoke" "${settings_timeout_seconds}" "${script_dir}/check-ssh-settings-smoke.sh"
  fi

  if (( run_surfaces == 1 )); then
    refresh_instance_args
    args=()
    if (( repo_shell_mode == 1 )) && [[ -n "${repo_shell_pid}" ]]; then
      args+=(--pid "${repo_shell_pid}")
    elif [[ -n "${instance_id}" ]]; then
      args+=(--id "${instance_id}")
    fi
    run_step_timeout "Running live surface responsive smoke" "${surfaces_timeout_seconds}" "${script_dir}/check-surface-responsive.sh" "${args[@]}"
    if (( run_launcher == 1 )); then
      if niri_headless_without_outputs; then
        printf '[INFO] Skipping targeted runtime warning regressions because the current Niri session exposes no wl_output in this headless environment.\n'
      else
        refresh_instance_args
        args=()
        if [[ -n "${instance_id}" ]]; then
          args+=(--id "${instance_id}")
        fi
        run_step_timeout "Running targeted runtime warning regressions" "${warnings_timeout_seconds}" "${script_dir}/check-runtime-warning-regressions.sh" "${args[@]}"
      fi
    else
      printf '[INFO] Skipping targeted runtime warning regressions because launcher capture is disabled.\n'
    fi
  fi

  if (( run_multibar == 1 )); then
    run_step_timeout "Running synthetic multibar smoke" "${multibar_timeout_seconds}" "${script_dir}/check-multibar-smoke.sh"
  fi

  printf '[INFO] Panel runtime verification completed. In headless/offscreen environments, multibar [SKIP] results can be expected. Manual visual QA is still required for final signoff.\n'
}

main "$@"
