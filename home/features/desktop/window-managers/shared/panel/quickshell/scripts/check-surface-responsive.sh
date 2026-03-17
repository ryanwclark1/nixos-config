#!/usr/bin/env bash
set -euo pipefail

runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
runtime_pid_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid"
script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_root="$(CDPATH= cd -- "${script_dir}/../src" >/dev/null && pwd)"

source "${script_dir}/runtime-warning-filter.sh"
instance_id=""
instance_pid=""
instance_dir=""
log_file=""
start_bytes=0
repo_shell_mode=0
repo_shell_pid=""
repo_shell_service_was_active=0
repo_shell_env=()
pass_count=0
warn_count=0
fail_count=0
surface_ids=(
  "notifCenter"
  "controlCenter"
  "networkMenu"
  "vpnMenu"
  "audioMenu"
  "bluetoothMenu"
  "printerMenu"
  "privacyMenu"
  "clipboardMenu"
  "recordingMenu"
  "musicMenu"
  "batteryMenu"
  "weatherMenu"
  "dateTimeMenu"
  "systemStatsMenu"
  "powerMenu"
  "notepad"
  "colorPicker"
  "displayConfig"
  "cavaPopup"
)

usage() {
  cat <<'EOF'
Usage: check-surface-responsive.sh [--id INSTANCE_ID] [--repo-shell]

Smoke-check the live QuickShell surface stack by:
  1. locating a running QuickShell instance,
  2. reloading the config,
  3. opening each popup/panel surface through Shell IPC,
  4. closing between surfaces,
  5. scanning new runtime log output for warnings/errors.

This validates runtime creation and close paths, not visual placement quality.
This is a live-session check and reports PASS/WARN/FAIL outcomes only; it does not use
the headless multibar [SKIP] classification.
EOF
}

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
  repo_shell_env+=("QS_DISABLE_NOTIFICATION_SERVER=1")
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
  env "${repo_shell_env[@]}" quickshell -p "${config_root}/shell.qml" >/tmp/quickshell-repo-surfaces.log 2>&1 &
  repo_shell_pid="$!"

  deadline=$((SECONDS + 20))
  while (( SECONDS < deadline )); do
    if run_ipc quickshell ipc --pid "${repo_shell_pid}" show >/dev/null; then
      sleep 1
      instance_pid="${repo_shell_pid}"
      printf '[INFO] Repo shell instance ready: pid %s\n' "${repo_shell_pid}"
      return 0
    fi
    sleep 0.5
  done

  printf 'Repo shell did not become IPC-ready in time. See /tmp/quickshell-repo-surfaces.log\n' >&2
  exit 1
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

shell_id_for_runtime_dir() {
  local runtime_dir="$1"
  local log_path="${runtime_dir}/log.log"
  local shell_id=""

  if [[ ! -f "${log_path}" ]]; then
    return 1
  fi

  shell_id="$(sed -n 's/.*Shell ID: "\([[:xdigit:]]\+\)".*/\1/p' "${log_path}" | head -n1)"
  [[ -n "${shell_id}" ]] || return 1
  printf '%s\n' "${shell_id}"
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
  local ids=()
  local shell_id

  while IFS= read -r pid; do
    [[ -n "${pid}" ]] || continue
    resolved="$(readlink -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid/${pid}" 2>/dev/null || true)"
    if [[ -n "${resolved}" && -S "${resolved}/ipc.sock" ]]; then
      shell_id="$(shell_id_for_runtime_dir "${resolved}" || true)"
      [[ -n "${shell_id}" ]] && ids+=("${shell_id}")
    fi
  done < <(ps -eo pid=,comm=,args= | awk '$2 ~ /quickshell/ || $3 ~ /quickshell/ { print $1 }')

  printf '%s\n' "${ids[@]}" | awk 'NF && !seen[$0]++'
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
      local shell_id=""
      shell_id="$(shell_id_for_runtime_dir "${dir}" || true)"
      [[ -n "${shell_id}" ]] && dirs+=("${shell_id}")
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

  if [[ -S "${direct_dir}/ipc.sock" ]] && shell_id_for_runtime_dir "${direct_dir}" >/dev/null 2>&1; then
    printf '%s\n' "${direct_dir}"
    return 0
  fi

  resolved_dir="$(
    rg -l --fixed-strings "Shell ID: \"${requested_id}\"" "${runtime_root}"/*/log.log 2>/dev/null \
      | xargs -r stat -c '%Y %n' 2>/dev/null \
      | sort -nr \
      | head -n1 \
      | cut -d' ' -f2- \
      | xargs -r dirname
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
  for attempt in 1 2 3; do
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
      sleep 0.2
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

  refreshed_pid="$(discover_reachable_pid || true)"
  if [[ -n "${refreshed_pid}" ]]; then
    refreshed_dir="$(readlink -f "${runtime_pid_root}/${refreshed_pid}" 2>/dev/null || true)"
    if [[ -n "${refreshed_dir}" && -S "${refreshed_dir}/ipc.sock" ]]; then
      refreshed_id="$(shell_id_for_runtime_dir "${refreshed_dir}" || basename "${refreshed_dir}")"
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

  if [[ -n "${instance_id}" ]]; then
    refreshed_dir="$(resolve_instance_dir "${instance_id}" || true)"
    if [[ -n "${refreshed_dir}" && -S "${refreshed_dir}/ipc.sock" ]]; then
      instance_pid=""
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

  return 1
}

main() {
  require_cmd quickshell
  require_cmd timeout
  require_cmd grep
  require_cmd tail
  require_cmd sed
  require_cmd sleep

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
    instance_id="$(shell_id_for_runtime_dir "${instance_dir}" || basename "${instance_dir}")"
  fi
  log_file="${instance_dir}/log.log"

  if [[ -f "${log_file}" ]]; then
    start_bytes="$(wc -c < "${log_file}")"
  fi

  if [[ -n "${instance_pid}" ]]; then
    if run_ipc quickshell ipc --pid "${instance_pid}" show >/dev/null; then
      pass "IPC reachable for pid ${instance_pid}"
    else
      fail "IPC unreachable for pid ${instance_pid}"
      printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
      exit 1
    fi
  else
    if run_ipc quickshell ipc --id "${instance_id}" show >/dev/null; then
      pass "IPC reachable for instance ${instance_id}"
    else
      fail "IPC unreachable for instance ${instance_id}"
      printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
      exit 1
    fi
  fi

  if call_ipc Shell reloadConfig >/dev/null; then
    pass "Shell.reloadConfig"
  else
    fail "Shell.reloadConfig"
  fi

  local surface_id
  for surface_id in "${surface_ids[@]}"; do
    if call_ipc Shell openSurface "${surface_id}" >/dev/null; then
      pass "Shell.openSurface ${surface_id}"
    else
      fail "Shell.openSurface ${surface_id}"
      continue
    fi
    sleep 0.2
    if call_ipc Shell closeAllSurfaces >/dev/null; then
      pass "Shell.closeAllSurfaces after ${surface_id}"
    else
      sleep 0.4
      refresh_instance_binding >/dev/null 2>&1 || true
      if call_ipc Shell closeAllSurfaces >/dev/null; then
        pass "Shell.closeAllSurfaces after ${surface_id} (after instance refresh)"
      else
        fail "Shell.closeAllSurfaces after ${surface_id}"
      fi
    fi
    sleep 0.1
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
    filtered="$(runtime_filter_log_delta surfaces "${delta_file}")"
    if runtime_log_contains_actionable_text "${filtered}"; then
      fail "New runtime warnings/errors detected"
      printf '%s\n' "${filtered}" >&2
    else
      pass "Only known non-blocking runtime warnings were observed"
    fi
  else
    pass "No new runtime warnings/errors in QuickShell log"
  fi

  printf '[INFO] Manual visual QA still required for top, bottom, left, and right bar anchors.\n'
  printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"
