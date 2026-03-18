#!/usr/bin/env bash
set -euo pipefail

runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_root="$(CDPATH= cd -- "${script_dir}/../src" >/dev/null && pwd)"
expected_config="$(realpath "${config_root}/shell.qml" 2>/dev/null || printf '%s' "${config_root}/shell.qml")"
instance_id=""
instance_pid=""
instance_dir=""
log_file=""
start_bytes=0
repo_shell_mode=0
repo_shell_pid=""
repo_shell_service_was_active=0
repo_shell_env=()
delta_file=""
pass_count=0
warn_count=0
fail_count=0

source "${script_dir}/runtime-warning-filter.sh"

usage() {
  cat <<'EOF'
Usage: check-runtime-warning-regressions.sh [--id INSTANCE_ID] [--repo-shell]

Reloads the shell, opens the targeted warning-regression surfaces:
  - audioMenu
  - controlCenter
  - aiChat
  - notifCenter
  - SettingsHub hooks tab

Then scans fresh QuickShell log output for new warnings/errors.
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

cleanup_repo_shell() {
  if [[ -n "${repo_shell_pid}" ]]; then
    kill "${repo_shell_pid}" >/dev/null 2>&1 || true
    wait "${repo_shell_pid}" >/dev/null 2>&1 || true
  fi
  if (( repo_shell_service_was_active == 1 )); then
    systemctl --user start quickshell.service >/dev/null 2>&1 || true
  fi
}

handle_termination() {
  trap - EXIT TERM INT
  cleanup_repo_shell
  exit 124
}

populate_repo_shell_env() {
  local line=""
  local key=""
  local value=""

  repo_shell_env=()
  repo_shell_env+=("QS_DISABLE_NOTIFICATION_SERVER=1")
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
  env "${repo_shell_env[@]}" quickshell -p "${config_root}/shell.qml" >/tmp/quickshell-runtime-warning-regressions.log 2>&1 &
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

  printf 'Repo shell did not become IPC-ready in time. See /tmp/quickshell-runtime-warning-regressions.log\n' >&2
  exit 1
}

resolve_instance_paths() {
  if [[ -n "${instance_pid}" ]]; then
    instance_dir="$(readlink -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid/${instance_pid}" 2>/dev/null || true)"
    if [[ -n "${instance_dir}" ]]; then
      instance_id="$(basename "${instance_dir}")"
      log_file="${instance_dir}/log.log"
      return 0
    fi
    discover_instance || true
    if [[ -n "${instance_id}" ]]; then
      instance_dir="${runtime_root}/${instance_id}"
      log_file="${instance_dir}/log.log"
      if [[ -S "${instance_dir}/ipc.sock" ]]; then
        instance_pid=""
        return 0
      fi
    fi
  fi

  if [[ -n "${instance_id}" ]]; then
    instance_dir="${runtime_root}/${instance_id}"
    log_file="${instance_dir}/log.log"
    [[ -S "${instance_dir}/ipc.sock" ]] && return 0
  fi

  return 1
}

discover_instance() {
  local candidate=""
  local show_output=""
  local log_path=""
  local launch_line=""

  if [[ ! -d "${runtime_root}" ]]; then
    return 1
  fi

  while IFS= read -r candidate; do
    show_output="$(quickshell ipc --id "${candidate}" show 2>/dev/null || true)"
    [[ -z "${show_output}" ]] && continue
    if ! printf '%s' "${show_output}" | rg -q "target Shell"; then
      continue
    fi

    log_path="${runtime_root}/${candidate}/log.log"
    launch_line="$(sed -n '1,6p' "${log_path}" 2>/dev/null | rg -m1 "Launching config:" || true)"
    if [[ -n "${launch_line}" ]] && printf '%s' "${launch_line}" | rg -q -F -- "${expected_config}"; then
      instance_id="${candidate}"
      return 0
    fi
  done < <(find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -printf '%T@ %f\n' 2>/dev/null | sort -nr | awk '{print $2}')

  return 1
}

call_ipc() {
  local target="$1"
  local action="$2"
  local attempt
  shift 2

  for attempt in 1 2 3; do
    if [[ -n "${instance_pid}" ]]; then
      if run_ipc quickshell ipc --pid "${instance_pid}" call "${target}" "${action}" "$@"; then
        return 0
      fi
    else
      if run_ipc quickshell ipc --id "${instance_id}" call "${target}" "${action}" "$@"; then
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
  instance_dir=""
  log_file=""

  if resolve_instance_paths; then
    if [[ -f "${log_file}" ]]; then
      start_bytes="$(wc -c < "${log_file}")"
    else
      start_bytes=0
    fi
    return 0
  fi

  if discover_instance && resolve_instance_paths; then
    if [[ -f "${log_file}" ]]; then
      start_bytes="$(wc -c < "${log_file}")"
    else
      start_bytes=0
    fi
    return 0
  fi

  return 1
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

main() {
  local filtered=""
  local start_byte=1
  local surface_id=""

  trap cleanup_repo_shell EXIT
  trap handle_termination TERM INT

  if (( repo_shell_mode == 1 )); then
    start_repo_shell
  elif [[ -z "${instance_id}" ]]; then
    discover_instance || {
      printf 'Could not find a running QuickShell instance for runtime warning checks.\n' >&2
      exit 1
    }
  fi

  resolve_instance_paths || {
    printf 'Could not resolve runtime paths for QuickShell instance.\n' >&2
    exit 1
  }

  delta_file="$(mktemp)"
  trap 'rm -f "${delta_file:-}"; cleanup_repo_shell' EXIT

  if [[ -f "${log_file}" ]]; then
    start_bytes="$(wc -c < "${log_file}")"
  fi

  if call_ipc Shell reloadConfig >/dev/null; then
    pass "Shell.reloadConfig"
  else
    fail "Shell.reloadConfig"
  fi

  for surface_id in audioMenu controlCenter aiChat notifCenter; do
    if call_ipc Shell openSurface "${surface_id}" >/dev/null; then
      pass "Shell.openSurface ${surface_id}"
    else
      fail "Shell.openSurface ${surface_id}"
    fi
    sleep 0.2
    if call_ipc Shell closeAllSurfaces >/dev/null; then
      pass "Shell.closeAllSurfaces after ${surface_id}"
    else
      fail "Shell.closeAllSurfaces after ${surface_id}"
    fi
    sleep 0.1
  done

  if call_ipc SettingsHub openTab hooks >/dev/null; then
    pass "SettingsHub.openTab hooks"
  else
    fail "SettingsHub.openTab hooks"
  fi
  sleep 0.2
  if call_ipc SettingsHub close >/dev/null; then
    pass "SettingsHub.close after hooks"
  else
    fail "SettingsHub.close after hooks"
  fi

  sleep 1

  if [[ -f "${log_file}" ]]; then
    if (( start_bytes > 0 )); then
      start_byte=$((start_bytes + 1))
    fi
    tail -c +"${start_byte}" "${log_file}" > "${delta_file}" || true
  fi

  if [[ -s "${delta_file}" ]]; then
    filtered="$(runtime_filter_log_delta targeted-surfaces "${delta_file}")"
    if runtime_log_contains_actionable_text "${filtered}"; then
      fail "New runtime warnings/errors detected in targeted surfaces"
      printf '%s\n' "${filtered}" >&2
    else
      pass "No targeted runtime warning regressions detected"
    fi
  else
    pass "No new runtime warnings/errors in QuickShell log"
  fi

  printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"
