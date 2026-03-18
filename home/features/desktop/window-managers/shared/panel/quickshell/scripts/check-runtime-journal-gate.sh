#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_root="$(CDPATH= cd -- "${script_dir}/../src" >/dev/null && pwd)"
runtime_pid_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid"
service_was_active=0
unit_name="quickshell-runtime-gate-$$"
unit_pid=""
instance_id=""
journal_since=""
repo_shell_env=()
pass_count=0
warn_count=0
fail_count=0

source "${script_dir}/runtime-warning-filter.sh"

usage() {
  cat <<'EOF'
Usage: check-runtime-journal-gate.sh

Runs the repo QuickShell shell under a transient user unit, exercises core launcher
and popup flows, then scans that unit's journal output for new actionable warnings/errors.
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

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 2
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

cleanup_service() {
  systemctl --user stop "${unit_name}" >/dev/null 2>&1 || true
  systemctl --user reset-failed "${unit_name}" >/dev/null 2>&1 || true
  if (( service_was_active == 1 )) && command -v systemctl >/dev/null 2>&1; then
    systemctl --user start quickshell.service >/dev/null 2>&1 || true
  fi
}

handle_termination() {
  trap - EXIT TERM INT
  cleanup_service
  exit 124
}

populate_repo_shell_env() {
  local line key value

  repo_shell_env=()
  repo_shell_env+=("QS_DISABLE_NOTIFICATION_SERVER=1")
  repo_shell_env+=("QS_SCRIPT_ROOT=${script_dir}")
  for key in HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP DESKTOP_SESSION; do
    value="${!key:-}"
    [[ -n "${value}" ]] && repo_shell_env+=("${key}=${value}")
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

resolve_instance_id() {
  local resolved=""
  [[ -n "${unit_pid}" && "${unit_pid}" != "0" ]] || return 1
  resolved="$(readlink -f "${runtime_pid_root}/${unit_pid}" 2>/dev/null || true)"
  [[ -n "${resolved}" && -S "${resolved}/ipc.sock" ]] || return 1
  instance_id="$(basename "${resolved}")"
  return 0
}

wait_for_unit() {
  local deadline

  deadline=$((SECONDS + 25))
  while (( SECONDS < deadline )); do
    unit_pid="$(systemctl --user show "${unit_name}" --property MainPID --value 2>/dev/null || true)"
    if [[ -n "${unit_pid}" && "${unit_pid}" != "0" ]] \
      && run_ipc quickshell ipc --pid "${unit_pid}" show >/dev/null \
      && resolve_instance_id; then
      printf '[INFO] %s ready: pid %s instance %s\n' "${unit_name}" "${unit_pid}" "${instance_id}"
      return 0
    fi
    sleep 0.5
  done

  printf '%s did not become IPC-ready in time.\n' "${unit_name}" >&2
  return 1
}

wait_for_query_ready() {
  local deadline

  deadline=$((SECONDS + 15))
  while (( SECONDS < deadline )); do
    if run_ipc quickshell ipc --pid "${unit_pid}" show >/dev/null && resolve_instance_id; then
      return 0
    fi
    sleep 0.2
  done

  return 1
}

call_ipc() {
  local target="$1"
  local action="$2"
  shift 2
  run_ipc quickshell ipc --pid "${unit_pid}" call "${target}" "${action}" "$@"
}

probe_ipc_action() {
  local label="$1"
  local target="$2"
  local action="$3"
  shift 3
  local attempt

  for attempt in 1 2 3 4 5; do
    if call_ipc "${target}" "${action}" "$@" >/dev/null; then
      pass "${label}"
      return 0
    fi
    wait_for_query_ready >/dev/null 2>&1 || true
    sleep 0.5
  done

  fail "${label}"
  return 1
}

reload_and_wait() {
  local label="$1"

  if call_ipc Shell reloadConfig >/dev/null; then
    pass "${label}"
  else
    fail "${label}"
    return 1
  fi

  if ! wait_for_query_ready; then
    fail "Shell reload did not return to query-ready state"
    return 1
  fi

  sleep 0.5
  return 0
}

surface_is_open() {
  local surface_id="$1"
  local state=""
  state="$(call_ipc Shell isSurfaceOpen "${surface_id}" 2>/dev/null || true)"
  [[ "${state}" == "true" ]]
}

start_transient_unit() {
  local run_args=()
  local env_entry=""

  if systemctl --user is-active --quiet quickshell.service; then
    service_was_active=1
    systemctl --user stop quickshell.service >/dev/null 2>&1 || true
    sleep 1
  fi

  populate_repo_shell_env
  journal_since="$(date '+%Y-%m-%d %H:%M:%S')"

  run_args=(systemd-run --user --unit "${unit_name}" --quiet --collect --same-dir)
  for env_entry in "${repo_shell_env[@]}"; do
    run_args+=(--setenv="${env_entry}")
  done
  run_args+=(quickshell -p "${config_root}/shell.qml")

  "${run_args[@]}" >/dev/null
  wait_for_unit
}

exercise_launcher() {
  probe_ipc_action "Launcher.openDrun" Launcher openDrun
  sleep 0.2

  probe_ipc_action "Launcher.openWeb" Launcher openWeb
  sleep 0.2

  probe_ipc_action "Launcher.openFiles" Launcher openFiles
  sleep 0.2

  probe_ipc_action "Launcher.openSystem" Launcher openSystem
  sleep 0.2

  probe_ipc_action "Launcher.toggle" Launcher toggle
}

exercise_surfaces() {
  local surface_id=""
  for surface_id in notifCenter controlCenter audioMenu dateTimeMenu clipboardMenu; do
    if probe_ipc_action "Shell.openSurface ${surface_id}" Shell openSurface "${surface_id}"; then
      :
    elif surface_is_open "${surface_id}"; then
      pass "Shell.openSurface ${surface_id} (already open)"
    else
      fail "Shell.openSurface ${surface_id}"
    fi
    sleep 0.2
    if probe_ipc_action "Shell.closeSurface ${surface_id}" Shell closeSurface "${surface_id}"; then
      :
    elif ! surface_is_open "${surface_id}"; then
      pass "Shell.closeSurface ${surface_id} (already closed)"
    else
      warn "Shell.closeSurface ${surface_id}"
    fi
    sleep 0.1
  done

  probe_ipc_action "SettingsHub.openTab hooks" SettingsHub openTab hooks
  sleep 0.2
  probe_ipc_action "SettingsHub.close" SettingsHub close
}

check_journal() {
  local journal_file filtered
  journal_file="$(mktemp)"
  journalctl --user -u "${unit_name}" --since "${journal_since}" --no-pager > "${journal_file}" 2>/dev/null || true
  filtered="$(runtime_filter_log_delta journal "${journal_file}")"
  rm -f "${journal_file}"

  if runtime_log_contains_actionable_text "${filtered}"; then
    fail "New actionable warnings/errors in ${unit_name} journal"
    printf '%s\n' "${filtered}" >&2
  else
    pass "No actionable warnings/errors in ${unit_name} journal"
  fi
}

main() {
  trap cleanup_service EXIT
  trap handle_termination TERM INT

  while [[ $# -gt 0 ]]; do
    case "$1" in
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

  require_cmd systemctl
  require_cmd systemd-run
  require_cmd journalctl
  require_cmd quickshell

  start_transient_unit

  if ! reload_and_wait "Shell.reloadConfig"; then
    printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
    exit 1
  fi
  exercise_launcher
  if ! reload_and_wait "Shell.reloadConfig before surface checks"; then
    printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
    exit 1
  fi
  sleep 0.5
  exercise_surfaces
  sleep 1
  check_journal

  printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"
