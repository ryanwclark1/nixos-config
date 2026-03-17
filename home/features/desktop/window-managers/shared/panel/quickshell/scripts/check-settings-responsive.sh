#!/usr/bin/env bash
set -euo pipefail

runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
runtime_pid_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid"
script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_root="$(CDPATH= cd -- "${script_dir}/../config" >/dev/null && pwd)"

source "${script_dir}/runtime-warning-filter.sh"

tab_ids=(
  "launcher"
  "launcher-search"
  "launcher-web"
  "launcher-modes"
  "launcher-runtime"
  "ai"
  "wallpaper"
  "bar-widgets"
  "bars"
  "system"
  "plugins"
  "theme"
  "hotkeys"
  "time-weather"
)

pass_count=0
warn_count=0
fail_count=0
repo_shell_mode=0
repo_shell_pid=""
repo_shell_service_was_active=0
repo_shell_env=()

pass() {
  printf '[PASS] %s\n' "$1"
  pass_count=$((pass_count + 1))
}

warn() {
  printf '[WARN] %s\n' "$1"
  warn_count=$((warn_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

usage() {
  cat <<'EOF'
Usage: check-settings-responsive.sh [--id INSTANCE_ID] [--repo-shell]

Smoke-check the live QuickShell settings surface by:
  1. locating a running QuickShell instance,
  2. reloading the config,
  3. opening SettingsHub,
  4. cycling the highest-risk settings tabs,
  5. scanning new runtime log output for warnings/errors.

If more than one live instance is present, pass --id INSTANCE_ID explicitly.
This is a live-session check and reports PASS/WARN/FAIL outcomes only; it does not use
the headless multibar [SKIP] classification.
EOF
}

instance_id=""
instance_pid=""
instance_dir=""
log_file=""
start_bytes=0

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

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 2
  fi
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

populate_repo_shell_env() {
  local line=""
  local key=""
  local value=""

  repo_shell_env=()
  for key in HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP DESKTOP_SESSION; do
    value="${!key:-}"
    if [[ -n "${value}" ]]; then
      repo_shell_env+=("${key}=${value}")
    fi
  done

  if (( ${#repo_shell_env[@]} > 0 )); then
    return 0
  fi

  while IFS= read -r line; do
    [[ "${line}" == *=* ]] || continue
    key="${line%%=*}"
    value="${line#*=}"
    case "${key}" in
      HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|NIRI_SOCKET|XDG_CURRENT_DESKTOP|DESKTOP_SESSION)
        [[ -n "${value}" ]] && repo_shell_env+=("${key}=${value}")
        ;;
    esac
  done < <(systemctl --user show-environment 2>/dev/null || true)
}

start_repo_shell() {
  local deadline
  local runtime_dir=""
  local runtime_id=""

  if ! command -v systemctl >/dev/null 2>&1; then
    printf 'systemctl is required for --repo-shell mode.\n' >&2
    exit 1
  fi

  if systemctl --user is-active --quiet quickshell.service; then
    repo_shell_service_was_active=1
    systemctl --user stop quickshell.service >/dev/null 2>&1 || true
    sleep 1
  fi

  populate_repo_shell_env
  env "${repo_shell_env[@]}" quickshell -p "${config_root}/shell.qml" >/tmp/quickshell-repo-settings.log 2>&1 &
  repo_shell_pid="$!"

  deadline=$((SECONDS + 20))
  while (( SECONDS < deadline )); do
    runtime_dir="$(readlink -f "${runtime_pid_root}/${repo_shell_pid}" 2>/dev/null || true)"
    runtime_id=""
    if [[ -n "${runtime_dir}" && -S "${runtime_dir}/ipc.sock" ]]; then
      runtime_id="$(basename "${runtime_dir}")"
    fi
    if [[ -n "${runtime_id}" ]] && run_ipc quickshell ipc --id "${runtime_id}" show >/dev/null; then
      sleep 1
      instance_pid="${repo_shell_pid}"
      instance_id="${runtime_id}"
      instance_dir="${runtime_dir}"
      printf '[INFO] Repo shell instance ready: pid %s id %s\n' "${repo_shell_pid}" "${runtime_id}"
      return 0
    fi
    sleep 0.5
  done

  printf 'Repo shell did not become IPC-ready in time. See /tmp/quickshell-repo-settings.log\n' >&2
  exit 1
}

run_ipc() {
  local output=""
  local status=0
  local attempt

  for attempt in 1 2 3 4 5; do
    output="$(timeout 5s "$@" 2>&1)"
    status=$?
    if [[ "${output}" == *"Not ready to accept queries yet."* ]] \
      || [[ "${output}" == *"No instance found for pid "* ]] \
      || [[ "${output}" == *"No running instances start with "* ]]; then
      sleep 0.2
      continue
    fi
    if [[ ${status} -eq 0 ]]; then
      return 0
    fi
    [[ -n "${output}" ]] && printf '%s\n' "${output}" >&2
    return "${status}"
  done

  [[ -n "${output}" ]] && printf '%s\n' "${output}" >&2
  return "${status}"
}

discover_running_pids() {
  local service_pid=""

  if command -v systemctl >/dev/null 2>&1; then
    service_pid="$(systemctl --user show quickshell.service --property MainPID --value 2>/dev/null || true)"
    if [[ "${service_pid}" =~ ^[0-9]+$ ]] && [[ "${service_pid}" != "0" ]]; then
      printf '%s\n' "${service_pid}"
    fi
  fi

  ps -eo pid=,comm=,args= \
    | awk '$2 ~ /quickshell/ || $3 ~ /quickshell/ { print $1 }' \
    | awk 'NF && !seen[$0]++'
}

discover_reachable_pid() {
  local candidate_pid
  while IFS= read -r candidate_pid; do
    [[ -n "${candidate_pid}" ]] || continue
    if run_ipc quickshell ipc --pid "${candidate_pid}" show >/dev/null; then
      printf '%s\n' "${candidate_pid}"
      return 0
    fi
  done < <(discover_running_pids)

  return 1
}

discover_instances_from_pid() {
  local pid
  local resolved
  local preferred=()
  local fallback=()
  local log_path
  local first_line

  while IFS= read -r pid; do
    [[ -n "${pid}" ]] || continue
    resolved="$(readlink -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid/${pid}" 2>/dev/null || true)"
    if [[ -n "${resolved}" && -S "${resolved}/ipc.sock" ]]; then
      log_path="${resolved}/log.log"
      first_line="$(sed -n '1p' "${log_path}" 2>/dev/null || true)"
      if [[ "${first_line}" == *'Launching config:'*'shell.qml"'* ]]; then
        preferred+=("$(basename "${resolved}")")
      else
        fallback+=("$(basename "${resolved}")")
      fi
    fi
  done < <(ps -eo pid=,comm=,args= | awk '$2 ~ /quickshell/ || $3 ~ /quickshell/ { print $1 }')

  if (( ${#preferred[@]} > 0 )); then
    printf '%s\n' "${preferred[@]}" | awk 'NF && !seen[$0]++'
  else
    printf '%s\n' "${fallback[@]}" | awk 'NF && !seen[$0]++'
  fi
}

discover_instances() {
  local dirs=()
  local dir

  mapfile -t dirs < <(discover_instances_from_pid)
  if (( ${#dirs[@]} > 0 )); then
    printf '%s\n' "${dirs[@]}"
    return 0
  fi

  if [[ -d "${runtime_root}" ]]; then
    while IFS= read -r dir; do
      dirs+=("$(basename "${dir}")")
    done < <(find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -print 2>/dev/null | sort)
  fi

  printf '%s\n' "${dirs[@]}"
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

resolve_instance_dir() {
  local requested_id="$1"
  local direct_dir="${runtime_root}/${requested_id}"
  local resolved_dir=""

  if [[ -S "${direct_dir}/ipc.sock" ]]; then
    printf '%s\n' "${direct_dir}"
    return 0
  fi

  resolved_dir="$(
    find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -name "${requested_id}" 2>/dev/null | head -n1
  )"

  if [[ -n "${resolved_dir}" && -S "${resolved_dir}/ipc.sock" ]]; then
    printf '%s\n' "${resolved_dir}"
    return 0
  fi

  return 1
}

call_ipc() {
  local target="$1"
  shift
  local attempt
  for attempt in 1 2 3 4 5 6; do
    if [[ -n "${instance_pid}" ]]; then
      if run_ipc quickshell ipc --pid "${instance_pid}" call "${target}" "$@"; then
        return 0
      fi
    else
      if run_ipc quickshell ipc --id "${instance_id}" call "${target}" "$@"; then
        return 0
      fi
    fi
    if ! refresh_instance_binding; then
      sleep 0.4
      continue
    fi
    sleep 0.2
  done
  return 1
}

refresh_instance_binding() {
  local refreshed_pid=""
  local refreshed_id=""
  local refreshed_dir=""
  local refreshed_log=""
  local attempt

  for attempt in 1 2 3 4 5 6 7 8; do
    refreshed_pid="$(discover_reachable_pid || true)"
    if [[ -n "${refreshed_pid}" ]]; then
      refreshed_dir="$(readlink -f "${runtime_pid_root}/${refreshed_pid}" 2>/dev/null || true)"
      if [[ -n "${refreshed_dir}" && -S "${refreshed_dir}/ipc.sock" ]]; then
        refreshed_id="$(basename "${refreshed_dir}")"
        instance_pid="${refreshed_pid}"
        instance_id="${refreshed_id}"
        instance_dir="${refreshed_dir}"
        refreshed_log="${instance_dir}/log.log"
        log_file="${refreshed_log}"
        if [[ -f "${log_file}" ]]; then
          start_bytes="$(wc -c < "${log_file}")"
        else
          start_bytes=0
        fi
        return 0
      fi
    fi

    refreshed_id="$(discover_reachable_instance || true)"
    if [[ -n "${refreshed_id}" ]]; then
      refreshed_dir="$(resolve_instance_dir "${refreshed_id}" || true)"
      if [[ -n "${refreshed_dir}" && -S "${refreshed_dir}/ipc.sock" ]]; then
        instance_pid=""
        instance_id="${refreshed_id}"
        instance_dir="${refreshed_dir}"
        refreshed_log="${instance_dir}/log.log"
        log_file="${refreshed_log}"
        if [[ -f "${log_file}" ]]; then
          start_bytes="$(wc -c < "${log_file}")"
        else
          start_bytes=0
        fi
        return 0
      fi
    fi

    sleep 0.4
  done

  return 1
}

main() {
  require_cmd quickshell
  require_cmd timeout
  require_cmd sed
  require_cmd tail
  require_cmd grep

  if (( repo_shell_mode == 1 )); then
    trap cleanup_repo_shell EXIT
    start_repo_shell
  fi

  if [[ -z "${instance_id}" && -z "${instance_pid}" ]]; then
    instance_pid="$(discover_reachable_pid || true)"
    if [[ -z "${instance_pid}" ]]; then
      printf 'No live QuickShell instances found under %s\n' "${runtime_root}" >&2
      exit 1
    fi
  fi

  local delta_file
  delta_file="$(mktemp)"
  trap "rm -f '${delta_file}'" EXIT

  if [[ -n "${instance_pid}" ]]; then
    instance_dir="$(readlink -f "${runtime_pid_root}/${instance_pid}" 2>/dev/null || true)"
  else
    instance_dir="$(resolve_instance_dir "${instance_id}" || true)"
  fi
  if [[ -z "${instance_dir}" || ! -S "${instance_dir}/ipc.sock" ]]; then
    printf 'Unable to resolve a live runtime directory for instance %s under %s\n' "${instance_pid:-$instance_id}" "${runtime_root}" >&2
    exit 1
  fi
  if [[ -z "${instance_id}" ]]; then
    instance_id="$(basename "${instance_dir}")"
  fi
  log_file="${instance_dir}/log.log"

  if [[ -f "${log_file}" ]]; then
    start_bytes="$(wc -c < "${log_file}")"
  fi

  if [[ -n "${instance_pid}" ]]; then
    if run_ipc quickshell ipc --pid "${instance_pid}" show >/dev/null; then
      pass "IPC reachable for pid ${instance_pid}"
    elif refresh_instance_binding && [[ -n "${instance_pid}" ]] && run_ipc quickshell ipc --pid "${instance_pid}" show >/dev/null; then
      pass "IPC reachable for pid ${instance_pid}"
    else
      fail "IPC unreachable for pid ${instance_pid}"
      printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
      exit 1
    fi
  else
    if run_ipc quickshell ipc --id "${instance_id}" show >/dev/null; then
      pass "IPC reachable for instance ${instance_id}"
    elif refresh_instance_binding; then
      if [[ -n "${instance_pid}" ]]; then
        if run_ipc quickshell ipc --pid "${instance_pid}" show >/dev/null; then
          pass "IPC reachable for pid ${instance_pid}"
        else
          fail "IPC unreachable for instance ${instance_id}"
          printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
          exit 1
        fi
      elif run_ipc quickshell ipc --id "${instance_id}" show >/dev/null; then
        pass "IPC reachable for instance ${instance_id}"
      else
        fail "IPC unreachable for instance ${instance_id}"
        printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
        exit 1
      fi
    else
      fail "IPC unreachable for instance ${instance_id}"
      printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
      exit 1
    fi
  fi

  if call_ipc Shell reloadConfig; then
    pass "Shell.reloadConfig"
  else
    fail "Shell.reloadConfig"
  fi

  if call_ipc SettingsHub open; then
    pass "SettingsHub.open"
  else
    fail "SettingsHub.open"
  fi

  for tab_id in "${tab_ids[@]}"; do
    if call_ipc SettingsHub openTab "${tab_id}"; then
      pass "SettingsHub.openTab ${tab_id}"
    else
      fail "SettingsHub.openTab ${tab_id}"
    fi
  done

  sleep 1

  if [[ -f "${log_file}" ]]; then
    local start_byte=1
    if (( start_bytes > 0 )); then
      start_byte=$((start_bytes + 1))
    fi
    tail -c +"${start_byte}" "${log_file}" > "${delta_file}" || true
  fi

  if [[ -s "${delta_file}" ]]; then
    local filtered
    filtered="$(runtime_filter_log_delta settings "${delta_file}")"
    if runtime_log_contains_actionable_text "${filtered}"; then
      fail "New runtime warnings/errors detected"
      printf '%s\n' "${filtered}" >&2
    else
      pass "Only known non-blocking runtime warnings were observed"
    fi
  else
    pass "No new runtime warnings/errors in QuickShell log"
  fi

  printf '[INFO] Manual visual QA still required for wide, laptop, and narrow/portrait layouts.\n'
  printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"
