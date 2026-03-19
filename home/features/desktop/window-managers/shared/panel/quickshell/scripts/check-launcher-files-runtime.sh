#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
config_root="$(CDPATH= cd -- "${script_dir}/../src" >/dev/null && pwd)"
launcher_qml="${config_root}/launcher/Launcher.qml"
expected_config="$(realpath "${config_root}/shell.qml" 2>/dev/null || printf '%s' "${config_root}/shell.qml")"

instance_id=""
ci_mode=0
repo_shell_mode=0
repo_shell_pid=""
repo_shell_service_was_active=0
repo_shell_env=()

pass_count=0
fail_count=0

usage() {
  cat <<'EOF'
Usage: check-launcher-files-runtime.sh [--id INSTANCE_ID] [--repo-shell] [--ci]

Validates file-mode launcher runtime behavior:
  - static IPC contract checks for files-mode diagnostics
  - live openFiles / diagnosticSetSearchText / launcherState / filesBackendStatus probes
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
  if rg -n -F -- "$needle" "$file" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
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
  repo_shell_env=()
  repo_shell_env+=("PATH=${script_dir}:${PATH}")
  repo_shell_env+=("QS_DISABLE_NOTIFICATION_SERVER=1")
  for key in HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP DESKTOP_SESSION; do
    value="${!key:-}"
    [[ -n "${value}" ]] && repo_shell_env+=("${key}=${value}")
  done
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
  local deadline runtime_dir
  if systemctl --user is-active --quiet quickshell.service; then
    repo_shell_service_was_active=1
    systemctl --user stop quickshell.service >/dev/null 2>&1 || true
    sleep 1
  fi
  populate_repo_shell_env
  env "${repo_shell_env[@]}" quickshell -p "${config_root}/shell.qml" >/tmp/quickshell-repo-launcher-files-runtime.log 2>&1 &
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
  printf 'Repo shell did not become IPC-ready in time. See /tmp/quickshell-repo-launcher-files-runtime.log\n' >&2
  exit 1
}

discover_reachable_instance() {
  local candidate show_output launch_line log_file fallback_candidate=""
  if [[ ! -d "${runtime_root}" ]]; then
    return 1
  fi
  while IFS= read -r candidate; do
    show_output="$(quickshell ipc --id "${candidate}" show 2>/dev/null || true)"
    [[ -n "${show_output}" ]] || continue
    printf '%s' "${show_output}" | rg -q 'target Launcher' || continue
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

launcher_action_available() {
  local action="$1"
  quickshell ipc --id "${instance_id}" show 2>/dev/null | rg -q "function ${action}\\("
}

call_ipc() {
  quickshell ipc --id "${instance_id}" call "$@"
}

json_probe() {
  local mode="$1"
  local expected="$2"
  node -e '
const fs = require("node:fs");
const [mode, expected] = process.argv.slice(1);
let raw = fs.readFileSync(0, "utf8").trim();
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
function fail(message) {
  console.error(message);
  process.exit(1);
}
if (mode === "launcher-mode") {
  if (payload.mode !== expected) fail(`mode=${payload.mode}`);
  process.exit(0);
}
if (mode === "launcher-query") {
  if (payload.searchText !== expected) fail(`searchText=${payload.searchText}`);
  if (payload.mode !== "files") fail(`mode=${payload.mode}`);
  process.exit(0);
}
if (mode === "backend-status") {
  if (typeof payload.backend !== "string" || payload.backend === "" || payload.backend === "none") fail(`backend=${payload.backend}`);
  if (typeof payload.indexReady !== "boolean") fail("indexReady missing");
  if (typeof payload.indexBuilding !== "boolean") fail("indexBuilding missing");
  if (typeof payload.indexSize !== "number") fail("indexSize missing");
  if (!payload.metrics || typeof payload.metrics !== "object") fail("metrics missing");
  if (!payload.cache || typeof payload.cache !== "object") fail("cache missing");
  process.exit(0);
}
fail(`unknown probe ${mode}`);
' "$mode" "$expected"
}

wait_for_probe() {
  local label="$1"
  local command="$2"
  local probe_mode="$3"
  local probe_value="$4"
  local deadline=$((SECONDS + 10))
  local payload
  while (( SECONDS < deadline )); do
    payload="$(eval "$command" 2>/dev/null || true)"
    if [[ -n "${payload}" ]] && printf '%s' "${payload}" | json_probe "${probe_mode}" "${probe_value}" >/dev/null 2>&1; then
      pass "$label"
      return 0
    fi
    sleep 0.25
  done
  fail "$label"
  return 1
}

main() {
  require_cmd quickshell
  require_cmd node
  require_cmd rg

  require_literal "$launcher_qml" 'function openFiles() {' "Launcher.openFiles IPC mapping"
  require_literal "$launcher_qml" 'function filesBackendStatus(): string {' "Launcher.filesBackendStatus IPC mapping"
  require_literal "$launcher_qml" 'function launcherState(): string {' "Launcher.launcherState IPC mapping"
  require_literal "$launcher_qml" 'function diagnosticSetSearchText(text: string): string {' "Launcher.diagnosticSetSearchText IPC mapping"

  if (( ci_mode == 1 )); then
    (( fail_count == 0 ))
    printf '[INFO] Launcher files runtime static summary: %d pass, %d fail\n' "${pass_count}" "${fail_count}"
    return 0
  fi

  if (( repo_shell_mode == 1 )); then
    trap cleanup_repo_shell EXIT
    trap handle_termination TERM INT
    start_repo_shell
  elif [[ -z "${instance_id}" ]]; then
    instance_id="$(discover_reachable_instance || true)"
  fi

  if [[ -z "${instance_id}" ]]; then
    printf 'No reachable quickshell instance found.\n' >&2
    exit 1
  fi

  launcher_action_available openFiles || fail "Launcher.openFiles discoverable"
  launcher_action_available launcherState || fail "Launcher.launcherState discoverable"
  launcher_action_available filesBackendStatus || fail "Launcher.filesBackendStatus discoverable"
  launcher_action_available diagnosticSetSearchText || fail "Launcher.diagnosticSetSearchText discoverable"

  call_ipc Launcher openFiles >/dev/null
  wait_for_probe "Launcher enters files mode" "call_ipc Launcher launcherState" "launcher-mode" "files"

  call_ipc Launcher diagnosticSetSearchText "/nixos" >/dev/null
  wait_for_probe "Launcher applies files search text" "call_ipc Launcher launcherState" "launcher-query" "/nixos"
  wait_for_probe "Launcher exposes files backend status" "call_ipc Launcher filesBackendStatus" "backend-status" ""

  call_ipc Launcher diagnosticSetSearchText "" >/dev/null || true
  call_ipc Launcher invokeEscapeAction >/dev/null || true

  printf '[INFO] Launcher files runtime summary: %d pass, %d fail\n' "${pass_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"
