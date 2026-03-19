#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
config_root="$(CDPATH= cd -- "${script_dir}/../src" >/dev/null && pwd)"
shell_root_qml="${config_root}/app/ShellRoot.qml"
surface_service_qml="${config_root}/services/SurfaceService.qml"
notification_center_qml="${config_root}/features/notifications/NotificationCenter.qml"
system_monitor_panel_qml="${config_root}/features/system/surfaces/SystemMonitorPanel.qml"
expected_config="$(realpath "${config_root}/shell.qml" 2>/dev/null || printf '%s' "${config_root}/shell.qml")"

source "${script_dir}/runtime-warning-filter.sh"

instance_id=""
ci_mode=0
repo_shell_mode=0
repo_shell_pid=""
repo_shell_service_was_active=0
repo_shell_env=()
pass_count=0
fail_count=0
violations=()

usage() {
  cat <<'EOF'
Usage: check-system-notification-surfaces.sh [--id INSTANCE_ID] [--repo-shell] [--ci]

Validates notification-center and system-monitor surface behavior:
  - static shell wiring for notifCenter and systemMonitor
  - live open/close and surface-switch behavior through Shell IPC
  - runtime log scan for new actionable warnings/errors
In --ci mode, only static checks are executed.
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

pass() {
  printf '[PASS] %s\n' "$1"
  pass_count=$((pass_count + 1))
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

require_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if ! rg -n -F -- "$needle" "$file" >/dev/null 2>&1; then
    violations+=("${label} missing in ${file}")
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

handle_termination() {
  trap - EXIT TERM INT
  cleanup_repo_shell
  exit 124
}

populate_repo_shell_env() {
  local line key value
  local has_wayland_session=0
  local found_graphics_env=0
  repo_shell_env=()
  repo_shell_env+=("PATH=${script_dir}:${PATH}")
  repo_shell_env+=("QS_DISABLE_NOTIFICATION_SERVER=1")
  for key in HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP DESKTOP_SESSION XDG_SESSION_TYPE DISPLAY; do
    value="${!key:-}"
    if [[ -n "${value}" ]]; then
      repo_shell_env+=("${key}=${value}")
      case "${key}" in
        HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|NIRI_SOCKET|DISPLAY)
          found_graphics_env=1
          ;;&
        WAYLAND_DISPLAY|NIRI_SOCKET)
          has_wayland_session=1
          ;;
      esac
    fi
  done
  if (( found_graphics_env == 0 )); then
    while IFS= read -r line; do
      [[ "${line}" == *=* ]] || continue
      key="${line%%=*}"
      value="${line#*=}"
      case "${key}" in
        HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|NIRI_SOCKET|XDG_CURRENT_DESKTOP|DESKTOP_SESSION|XDG_SESSION_TYPE|DISPLAY)
          if [[ -n "${value}" ]]; then
            repo_shell_env+=("${key}=${value}")
            case "${key}" in
              HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|NIRI_SOCKET|DISPLAY)
                found_graphics_env=1
                ;;&
              WAYLAND_DISPLAY|NIRI_SOCKET)
                has_wayland_session=1
                ;;
            esac
          fi
          ;;
      esac
    done < <(systemctl --user show-environment 2>/dev/null || true)
  fi
  if (( has_wayland_session == 1 )); then
    repo_shell_env+=("QT_QPA_PLATFORM=wayland")
  fi
}

start_repo_shell() {
  local deadline runtime_dir
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
  env "${repo_shell_env[@]}" quickshell -p "${config_root}/shell.qml" >/tmp/quickshell-repo-system-notifications.log 2>&1 &
  repo_shell_pid="$!"
  deadline=$((SECONDS + 20))
  while (( SECONDS < deadline )); do
    if quickshell ipc --pid "${repo_shell_pid}" show >/dev/null 2>&1; then
      sleep 1
      runtime_dir="$(readlink -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid/${repo_shell_pid}" 2>/dev/null || true)"
      instance_id="$(basename "${runtime_dir}")"
      printf '[INFO] Repo shell instance ready: pid %s\n' "${repo_shell_pid}"
      return 0
    fi
    sleep 0.5
  done
  printf 'Repo shell did not become IPC-ready in time. See /tmp/quickshell-repo-system-notifications.log\n' >&2
  exit 1
}

discover_reachable_instance() {
  local candidate show_output log_file launch_line fallback_candidate=""
  if [[ ! -d "${runtime_root}" ]]; then
    return 1
  fi
  while IFS= read -r candidate; do
    show_output="$(quickshell ipc --id "${candidate}" show 2>/dev/null || true)"
    [[ -n "${show_output}" ]] || continue
    printf '%s' "${show_output}" | rg -q 'target Shell' || continue
    log_file="${runtime_root}/${candidate}/log.log"
    launch_line="$(sed -n '1,6p' "${log_file}" 2>/dev/null | rg -m1 'Launching config:' || true)"
    if [[ -n "${launch_line}" ]] && printf '%s' "${launch_line}" | rg -q -F -- "${expected_config}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
    [[ -z "${fallback_candidate}" ]] && fallback_candidate="${candidate}"
  done < <(find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -printf '%T@ %f\n' 2>/dev/null | sort -nr | awk '{print $2}')
  [[ -n "${fallback_candidate}" ]] && printf '%s\n' "${fallback_candidate}"
}

wait_for_instance_ready() {
  local deadline=$((SECONDS + 15))
  local discovered=""
  while (( SECONDS < deadline )); do
    if quickshell ipc --id "${instance_id}" show >/dev/null 2>&1; then
      return 0
    fi
    discovered="$(discover_reachable_instance || true)"
    if [[ -n "${discovered}" ]]; then
      instance_id="${discovered}"
      if quickshell ipc --id "${instance_id}" show >/dev/null 2>&1; then
        return 0
      fi
    fi
    sleep 0.2
  done
  return 1
}

ipc_error_is_retryable() {
  local output="$1"
  printf '%s' "${output}" | rg -q 'No running instances start with|Not ready to accept queries yet'
}

call_ipc() {
  local target="$1"
  local action="$2"
  shift 2
  local output=""
  local attempt
  for attempt in $(seq 1 8); do
    wait_for_instance_ready >/dev/null 2>&1 || true
    output="$(quickshell ipc --id "${instance_id}" call "${target}" "${action}" "$@" 2>&1)" && {
      printf '%s\n' "${output}"
      return 0
    }
    if ipc_error_is_retryable "${output}"; then
      sleep 0.25
      continue
    fi
    printf '%s\n' "${output}" >&2
    return 1
  done
  printf '%s\n' "${output}" >&2
  return 1
}

surface_is_open() {
  local surface_id="$1"
  local state=""
  state="$(call_ipc Shell isSurfaceOpen "${surface_id}" 2>/dev/null | tr -d '\r\n' || true)"
  [[ "${state}" == "true" ]]
}

wait_for_surface_state() {
  local surface_id="$1"
  local expected="$2"
  local deadline=$((SECONDS + 10))
  while (( SECONDS < deadline )); do
    if [[ "${expected}" == "open" ]]; then
      if surface_is_open "${surface_id}"; then
        return 0
      fi
    else
      if ! surface_is_open "${surface_id}"; then
        return 0
      fi
    fi
    sleep 0.2
  done
  return 1
}

wait_for_exclusive_surface() {
  local open_surface="$1"
  local closed_surface="$2"
  local deadline=$((SECONDS + 10))
  while (( SECONDS < deadline )); do
    if surface_is_open "${open_surface}" && ! surface_is_open "${closed_surface}"; then
      return 0
    fi
    sleep 0.2
  done
  return 1
}

static_checks() {
  require_literal "${shell_root_qml}" 'readonly property bool notifCenterVisible: root.isSurfaceOpen("notifCenter")' "ShellRoot notifCenter visibility state"
  require_literal "${shell_root_qml}" 'readonly property bool systemMonitorVisible: root.isSurfaceOpen("systemMonitor")' "ShellRoot systemMonitor visibility state"
  require_literal "${shell_root_qml}" 'LazyLoader {' "ShellRoot lazy-loader usage present"
  require_literal "${shell_root_qml}" 'active: root.notifCenterVisible' "ShellRoot notifCenter lazy-loader activation"
  require_literal "${shell_root_qml}" 'active: root.systemMonitorVisible' "ShellRoot systemMonitor lazy-loader activation"
  require_literal "${shell_root_qml}" 'onCloseRequested: root.closeSurface("notifCenter")' "ShellRoot notifCenter close wiring"
  require_literal "${shell_root_qml}" 'onCloseRequested: root.closeSurface("systemMonitor")' "ShellRoot systemMonitor close wiring"
  require_literal "${surface_service_qml}" 'notifCenter: {' "SurfaceService notifCenter registry entry"
  require_literal "${surface_service_qml}" 'systemMonitor: {' "SurfaceService systemMonitor registry entry"
  require_literal "${notification_center_qml}" 'property bool showContent: false' "NotificationCenter showContent state"
  require_literal "${notification_center_qml}" 'visible: root.showContent || ncSlideAnim.running || ncFadeAnim.running' "NotificationCenter visibility animation guard"
  require_literal "${system_monitor_panel_qml}" 'property bool showContent: false' "SystemMonitorPanel showContent state"
  require_literal "${system_monitor_panel_qml}" 'visible: showContent || slidePanel.x < panelWidth' "SystemMonitorPanel visibility animation guard"

  if (( ${#violations[@]} > 0 )); then
    local violation
    for violation in "${violations[@]}"; do
      fail "${violation}"
    done
  else
    pass "Static notification/system surface contracts present"
  fi
}

runtime_checks() {
  local instance_dir log_file start_bytes=0 delta_file filtered
  delta_file="$(mktemp)"
  trap "rm -f '${delta_file}'; cleanup_repo_shell" EXIT TERM INT

  instance_dir="${runtime_root}/${instance_id}"
  log_file="${instance_dir}/log.log"

  if [[ ! -S "${instance_dir}/ipc.sock" ]]; then
    fail "Instance ${instance_id} missing ipc socket"
    return
  fi

  if [[ -f "${log_file}" ]]; then
    start_bytes="$(wc -c < "${log_file}")"
  fi

  if quickshell ipc --id "${instance_id}" show >/dev/null 2>&1; then
    pass "IPC reachable for instance ${instance_id}"
  else
    fail "IPC unreachable for instance ${instance_id}"
    return
  fi

  if call_ipc Shell reloadConfig >/dev/null 2>&1; then
    pass "Shell.reloadConfig"
    wait_for_instance_ready >/dev/null 2>&1 || true
    sleep 0.5
  else
    fail "Shell.reloadConfig"
    return
  fi

  if call_ipc Shell closeAllSurfaces >/dev/null 2>&1 \
      && wait_for_surface_state "notifCenter" "closed" \
      && wait_for_surface_state "systemMonitor" "closed"; then
    pass "Shell.closeAllSurfaces resets notifCenter and systemMonitor"
  else
    fail "Shell.closeAllSurfaces resets notifCenter and systemMonitor"
  fi

  if call_ipc Shell openSurface "notifCenter" >/dev/null 2>&1 \
      && wait_for_exclusive_surface "notifCenter" "systemMonitor"; then
    pass "Shell.openSurface notifCenter opens notification center"
  else
    fail "Shell.openSurface notifCenter opens notification center"
  fi

  if call_ipc Shell openSurface "systemMonitor" >/dev/null 2>&1 \
      && wait_for_exclusive_surface "systemMonitor" "notifCenter"; then
    pass "Shell.openSurface systemMonitor replaces notification center"
  else
    fail "Shell.openSurface systemMonitor replaces notification center"
  fi

  if call_ipc Shell closeAllSurfaces >/dev/null 2>&1 \
      && wait_for_surface_state "notifCenter" "closed" \
      && wait_for_surface_state "systemMonitor" "closed"; then
    pass "Shell.closeAllSurfaces closes system-oriented panels"
  else
    fail "Shell.closeAllSurfaces closes system-oriented panels"
  fi

  if call_ipc Shell openSurface "systemMonitor" >/dev/null 2>&1 \
      && wait_for_exclusive_surface "systemMonitor" "notifCenter"; then
    pass "System monitor opens from a closed state"
  else
    fail "System monitor opens from a closed state"
  fi

  if call_ipc Shell openSurface "notifCenter" >/dev/null 2>&1 \
      && wait_for_exclusive_surface "notifCenter" "systemMonitor"; then
    pass "Notification center replaces system monitor"
  else
    fail "Notification center replaces system monitor"
  fi

  if call_ipc Shell closeAllSurfaces >/dev/null 2>&1 \
      && wait_for_surface_state "notifCenter" "closed" \
      && wait_for_surface_state "systemMonitor" "closed"; then
    pass "Final closeAllSurfaces leaves both surfaces closed"
  else
    fail "Final closeAllSurfaces leaves both surfaces closed"
  fi

  sleep 1

  if [[ -f "${log_file}" ]]; then
    local start_byte=1
    if (( start_bytes > 0 )); then
      start_byte=$((start_bytes + 1))
    fi
    tail -c +"${start_byte}" "${log_file}" > "${delta_file}" || true
  fi

  if [[ -s "${delta_file}" ]]; then
    filtered="$(runtime_filter_log_delta targeted-surfaces "${delta_file}")"
    if runtime_log_contains_actionable_text "${filtered}"; then
      fail "No new actionable warnings/errors in notification/system runtime log"
      printf '%s\n' "${filtered}" >&2
    else
      pass "No new actionable warnings/errors in notification/system runtime log"
    fi
  else
    pass "No new notification/system runtime log output"
  fi

  rm -f "${delta_file}"
  trap "cleanup_repo_shell" EXIT TERM INT
}

main() {
  require_cmd quickshell
  require_cmd rg

  if (( repo_shell_mode == 1 )); then
    trap handle_termination EXIT TERM INT
    start_repo_shell
  elif (( ci_mode == 0 )) && [[ -z "${instance_id}" ]]; then
    instance_id="$(discover_reachable_instance || true)"
  fi

  static_checks
  if (( ci_mode == 1 )); then
    printf '[INFO] Notification/system surface summary: %d pass, %d fail\n' "${pass_count}" "${fail_count}"
    (( fail_count == 0 ))
    return
  fi

  if [[ -z "${instance_id}" ]]; then
    fail "No reachable QuickShell instance found for notification/system surface checks"
    printf '[INFO] Notification/system surface summary: %d pass, %d fail\n' "${pass_count}" "${fail_count}"
    exit 1
  fi

  runtime_checks
  printf '[INFO] Notification/system surface summary: %d pass, %d fail\n' "${pass_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"
