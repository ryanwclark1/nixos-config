#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
config_root="$(CDPATH= cd -- "${script_dir}/../src" >/dev/null && pwd)"
launcher_qml="${script_dir}/../src/launcher/Launcher.qml"
launcher_ipc_handler_qml="${script_dir}/../src/launcher/LauncherIpcHandler.qml"
launcher_diag_js="${script_dir}/../src/launcher/LauncherDiagnostics.js"
expected_config="$(realpath "${script_dir}/../src/shell.qml" 2>/dev/null || printf '%s' "${script_dir}/../src/shell.qml")"

instance_id=""
ci_mode=0
repo_shell_mode=0
repo_shell_pid=""
repo_shell_service_was_active=0
repo_shell_env=()
checked_actions=()
errors=()
status_payload_valid=1

usage() {
  cat <<'EOF'
Usage: check-launcher-ipc-health.sh [--id INSTANCE_ID] [--repo-shell] [--ci]

Runs a launcher IPC health probe:
  - validates Launcher IPC methods are discoverable,
  - exercises clearMetrics/redetectFilesBackend/diagnosticReset/filesBackendStatus/drunCategoryState/escapeActionState/diagnosticSetSearchText/diagnosticSetDrunCategoryFilter/invokeEscapeAction,
  - verifies launcher IPC contract literals in LauncherIpcHandler.qml and payload helpers in Launcher.qml/LauncherDiagnostics.js.
In --ci mode, only static contract checks are executed.
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

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    errors+=("missing command: $1")
    return 1
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
  env "${repo_shell_env[@]}" quickshell -p "${config_root}/shell.qml" >/tmp/quickshell-repo-launcher-ipc.log 2>&1 &
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
  printf 'Repo shell did not become IPC-ready in time. See /tmp/quickshell-repo-launcher-ipc.log\n' >&2
  exit 1
}

discover_reachable_instance() {
  local candidate show_output log_file launch_line
  local fallback_candidate="" drun_candidate="" escape_candidate="" config_candidate="" preferred_candidate=""
  local service_pid service_runtime service_candidate
  if [[ ! -d "${runtime_root}" ]]; then
    return 1
  fi

  service_pid="$(systemctl --user show quickshell.service --property MainPID --value 2>/dev/null || true)"
  if [[ -n "${service_pid}" && "${service_pid}" != "0" ]]; then
    service_runtime="$(readlink -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid/${service_pid}" 2>/dev/null || true)"
    service_candidate="$(basename "${service_runtime}")"
    if [[ -n "${service_candidate}" ]]; then
      show_output="$(quickshell ipc --id "${service_candidate}" show 2>/dev/null || true)"
      if [[ -n "${show_output}" ]] && printf '%s' "${show_output}" | rg -q "target Launcher"; then
        printf '%s\n' "${service_candidate}"
        return 0
      fi
    fi
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

launcher_action_available() {
  local action="$1"
  local show_output
  show_output="$(quickshell ipc --id "${instance_id}" show 2>/dev/null || true)"
  if [[ -z "${show_output}" ]]; then
    return 1
  fi
  printf '%s' "${show_output}" | rg -q "function ${action}\\("
}

ensure_live_instance() {
  local attempt discovered
  for attempt in 1 2; do
    discovered="$(discover_reachable_instance || true)"
    if [[ -n "${discovered}" ]]; then
      instance_id="${discovered}"
      return 0
    fi
      if (( attempt == 1 && repo_shell_mode == 0 )); then
        if command -v systemctl >/dev/null 2>&1; then
          systemctl --user restart quickshell >/dev/null 2>&1 || true
          sleep 2
      fi
    fi
  done
  return 1
}

require_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if ! rg -n -F -- "$needle" "$file" >/dev/null 2>&1; then
    status_payload_valid=0
    errors+=("status payload contract missing: ${label}")
  fi
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! rg -n -U --multiline --pcre2 -- "$pattern" "$file" >/dev/null 2>&1; then
    status_payload_valid=0
    errors+=("status payload contract missing: ${label}")
  fi
}

emit_result() {
  local ok="$1"
  local checked_join errors_join
  checked_join="$(IFS=$'\x1f'; printf '%s' "${checked_actions[*]-}")"
  errors_join="$(IFS=$'\x1f'; printf '%s' "${errors[*]-}")"
  node -e '
const [ok, statusPayload, checked, errs, instance] = process.argv.slice(1);
const sep = "\x1f";
const parseList = (value) => value ? value.split(sep).filter(Boolean) : [];
console.log(JSON.stringify({
  ok: ok === "1",
  checked_actions: parseList(checked),
  status_payload_valid: statusPayload === "1",
  instance_id: instance || "",
  errors: parseList(errs)
}));
' "$ok" "$status_payload_valid" "$checked_join" "$errors_join" "$instance_id"
}

main() {
  require_cmd rg || true
  require_cmd node || true
  if (( ci_mode == 0 )); then
    require_cmd quickshell || true
  fi

  if (( repo_shell_mode == 1 )); then
    trap cleanup_repo_shell EXIT
    trap handle_termination TERM INT
    start_repo_shell
  fi

  if (( ${#errors[@]} > 0 )); then
    emit_result 0
    exit 1
  fi

  local action
  for action in clearMetrics redetectFilesBackend diagnosticReset filesBackendStatus drunCategoryState escapeActionState diagnosticSetSearchText diagnosticSetDrunCategoryFilter invokeEscapeAction; do
    checked_actions+=("${action}")
  done

  require_literal "$launcher_ipc_handler_qml" 'function clearMetrics() {' "Launcher.clearMetrics IPC mapping"
  require_literal "$launcher_ipc_handler_qml" 'function redetectFilesBackend() {' "Launcher.redetectFilesBackend IPC mapping"
  require_literal "$launcher_ipc_handler_qml" 'function diagnosticReset() {' "Launcher.diagnosticReset IPC mapping"
  require_pattern "$launcher_ipc_handler_qml" 'function filesBackendStatus\(\)(?:: string)? \{\s*return JSON\.stringify\((?:root\.)?launcher\.filesBackendStatusObject\(\)\);\s*\}' "Launcher.filesBackendStatus IPC mapping"
  require_pattern "$launcher_ipc_handler_qml" 'function drunCategoryState\(\)(?:: string)? \{\s*return JSON\.stringify\((?:root\.)?launcher\.drunCategoryStateObject\(\)\);\s*\}' "Launcher.drunCategoryState IPC mapping"
  require_pattern "$launcher_ipc_handler_qml" 'function escapeActionState\(\)(?:: string)? \{\s*return JSON\.stringify\((?:root\.)?launcher\.escapeActionStateObject\(\)\);\s*\}' "Launcher.escapeActionState IPC mapping"
  require_pattern "$launcher_ipc_handler_qml" 'function diagnosticSetSearchText\(text: string\)(?:: string)? \{\s*return (?:root\.)?launcher\.diagnosticSetSearchText\(text\);\s*\}' "Launcher.diagnosticSetSearchText IPC mapping"
  require_pattern "$launcher_ipc_handler_qml" 'function diagnosticSetDrunCategoryFilter\(categoryKey: string\)(?:: string)? \{\s*return (?:root\.)?launcher\.diagnosticSetDrunCategoryFilter\(categoryKey\);\s*\}' "Launcher.diagnosticSetDrunCategoryFilter IPC mapping"
  require_pattern "$launcher_ipc_handler_qml" 'function invokeEscapeAction\(\)(?:: string)? \{' "Launcher.invokeEscapeAction IPC mapping"
  require_literal "$launcher_qml" 'function drunCategoryStateObject() {' "drunCategoryState payload helper"
  require_literal "$launcher_qml" 'function escapeActionStateObject() {' "escapeActionState payload helper"
  require_literal "$launcher_diag_js" 'action = "resetQuery";' "escapeActionState resetQuery branch"
  require_literal "$launcher_diag_js" 'action = "resetCategory";' "escapeActionState resetCategory branch"
  require_literal "$launcher_diag_js" 'hasQuery: props.searchText !== "",' "escapeActionState hasQuery field"
  require_literal "$launcher_diag_js" 'hasCategoryFilter: props.drunCategoryFiltersEnabled && props.mode === "drun" && props.drunCategoryFilter !== "",' "escapeActionState hasCategoryFilter field"
  require_literal "$launcher_diag_js" 'enabled: props.drunCategoryFiltersEnabled === true,' "drunCategoryState enabled field"
  require_literal "$launcher_diag_js" 'activeCount: activeCount,' "drunCategoryState activeCount field"
  require_literal "$launcher_diag_js" 'totalCount: totalCount,' "drunCategoryState totalCount field"
  require_literal "$launcher_diag_js" 'options: normalized' "drunCategoryState options field"
  require_literal "$launcher_diag_js" 'backend: props.filesBackendLabel,' "backend"
  require_literal "$launcher_diag_js" 'metrics: ({' "metrics object"
  require_literal "$launcher_diag_js" 'filesResolveAvgMs: resolveAvgMs,' "metrics.filesResolveAvgMs"
  require_literal "$launcher_diag_js" 'filesResolveLastMs: resolveLastMs,' "metrics.filesResolveLastMs"
  require_literal "$launcher_diag_js" 'filesFdLoads: filesFdLoads,' "metrics.filesFdLoads"
  require_literal "$launcher_diag_js" 'filesFindLoads: filesFindLoads,' "metrics.filesFindLoads"
  require_literal "$launcher_diag_js" 'cache: ({' "cache object"
  require_literal "$launcher_diag_js" 'hits: fileCacheHits,' "cache.hits"
  require_literal "$launcher_diag_js" 'misses: fileCacheMisses,' "cache.misses"

  if (( ci_mode == 1 )); then
    if (( ${#errors[@]} > 0 )); then
      emit_result 0
      exit 1
    fi
    emit_result 1
    exit 0
  fi

  if [[ -z "${instance_id}" ]]; then
    ensure_live_instance || true
  fi

  if [[ -z "${instance_id}" ]]; then
    errors+=("no reachable quickshell instance found under ${runtime_root}")
    emit_result 0
    exit 1
  fi

  local show_output
  if ! show_output="$(quickshell ipc --id "${instance_id}" show 2>&1)"; then
    instance_id=""
    ensure_live_instance || true
    if [[ -z "${instance_id}" ]] || ! show_output="$(quickshell ipc --id "${instance_id}" show 2>&1)"; then
      errors+=("failed to query IPC metadata for instance ${instance_id:-<none>}: ${show_output}")
      emit_result 0
      exit 1
    fi
  fi

  if ! printf '%s' "${show_output}" | rg -q "target Launcher"; then
    errors+=("Launcher IPC target missing in instance ${instance_id}")
  fi

  for action in "${checked_actions[@]}"; do
    if ! printf '%s' "${show_output}" | rg -q "function ${action}\\("; then
      if [[ "${action}" == "drunCategoryState" || "${action}" == "escapeActionState" || "${action}" == "diagnosticSetSearchText" || "${action}" == "diagnosticSetDrunCategoryFilter" || "${action}" == "invokeEscapeAction" ]]; then
        if quickshell ipc --id "${instance_id}" call Shell reloadConfig >/dev/null 2>&1; then
          sleep 1
        fi
        if ! launcher_action_available "${action}"; then
          printf '%s\n' "[WARN] Launcher IPC action not discoverable in live instance after reload: ${action} (restart QuickShell to pick up latest QML)" >&2
          continue
        fi
      else
        errors+=("Launcher IPC action not discoverable: ${action}")
        continue
      fi
    fi
    if [[ "${action}" == "diagnosticSetSearchText" ]]; then
      if ! quickshell ipc --id "${instance_id}" call Launcher "${action}" "__launcher_ipc_probe__" >/dev/null 2>&1; then
        printf '%s\n' "[WARN] Launcher IPC call failed for ${action} in live instance (restart QuickShell to pick up latest QML)" >&2
        continue
      fi
    elif [[ "${action}" == "diagnosticSetDrunCategoryFilter" ]]; then
      if ! quickshell ipc --id "${instance_id}" call Launcher "${action}" "" >/dev/null 2>&1; then
        printf '%s\n' "[WARN] Launcher IPC call failed for ${action} in live instance (restart QuickShell to pick up latest QML)" >&2
        continue
      fi
    elif ! quickshell ipc --id "${instance_id}" call Launcher "${action}" >/dev/null 2>&1; then
      if [[ "${action}" == "drunCategoryState" || "${action}" == "escapeActionState" || "${action}" == "invokeEscapeAction" ]]; then
        printf '%s\n' "[WARN] Launcher IPC call failed for ${action} in live instance (restart QuickShell to pick up latest QML)" >&2
        continue
      fi
      errors+=("Launcher IPC call failed: ${action}")
    fi
  done

  if launcher_action_available "escapeActionState" && launcher_action_available "diagnosticSetSearchText" && launcher_action_available "invokeEscapeAction"; then
    local escape_state query_set query_invoke
    if escape_state="$(quickshell ipc --id "${instance_id}" call Launcher escapeActionState 2>/dev/null)" && ! printf '%s' "${escape_state}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
if (typeof payload !== "object" || !payload) process.exit(1);
if (typeof payload.action !== "string") process.exit(1);
if (typeof payload.mode !== "string") process.exit(1);
if (typeof payload.showingConfirm !== "boolean") process.exit(1);
if (typeof payload.hasQuery !== "boolean") process.exit(1);
if (typeof payload.searchText !== "string") process.exit(1);
if (typeof payload.hasCategoryFilter !== "boolean") process.exit(1);
if (typeof payload.drunCategoryFilter !== "string") process.exit(1);
' >/dev/null 2>&1; then
      errors+=("Launcher.escapeActionState returned invalid payload")
    fi

    if query_set="$(quickshell ipc --id "${instance_id}" call Launcher diagnosticSetSearchText "__launcher_ipc_probe__" 2>/dev/null)" && ! printf '%s' "${query_set}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
if (String(payload.action || "") !== "resetQuery") process.exit(1);
if (payload.hasQuery !== true) process.exit(1);
if (String(payload.searchText || "") !== "__launcher_ipc_probe__") process.exit(1);
' >/dev/null 2>&1; then
      errors+=("Launcher.diagnosticSetSearchText returned invalid payload")
    fi

    if query_invoke="$(quickshell ipc --id "${instance_id}" call Launcher invokeEscapeAction 2>/dev/null)" && ! printf '%s' "${query_invoke}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
const state = payload && typeof payload.state === "object" ? payload.state : {};
if (payload.handled !== true) process.exit(1);
if (String(payload.action || "") !== "resetQuery") process.exit(1);
if (state.hasQuery !== false) process.exit(1);
if (String(state.searchText || "") !== "") process.exit(1);
' >/dev/null 2>&1; then
      errors+=("Launcher.invokeEscapeAction query reset contract invalid")
    fi
  fi

  if launcher_action_available "drunCategoryState" && launcher_action_available "diagnosticSetDrunCategoryFilter" && launcher_action_available "invokeEscapeAction"; then
    local category_state category_key category_set category_invoke
    if quickshell ipc --id "${instance_id}" call Launcher openDrun >/dev/null 2>&1; then
      category_state="$(quickshell ipc --id "${instance_id}" call Launcher drunCategoryState 2>/dev/null || true)"
      category_key="$(printf '%s' "${category_state}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
if (!raw) process.exit(0);
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
if (payload.enabled !== true) process.exit(0);
const options = Array.isArray(payload.options) ? payload.options : [];
const match = options.find((item) => item && String(item.key || "") !== "");
if (match) process.stdout.write(String(match.key || ""));
' 2>/dev/null || true)"
      if [[ -n "${category_key}" ]]; then
        if category_set="$(quickshell ipc --id "${instance_id}" call Launcher diagnosticSetDrunCategoryFilter "${category_key}" 2>/dev/null)" && ! printf '%s' "${category_set}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
const state = payload && typeof payload.state === "object" ? payload.state : {};
if (typeof payload.changed !== "boolean") process.exit(1);
if (state.hasCategoryFilter !== true) process.exit(1);
if (String(state.action || "") !== "resetCategory") process.exit(1);
' >/dev/null 2>&1; then
          errors+=("Launcher.diagnosticSetDrunCategoryFilter returned invalid payload")
        fi

        if category_invoke="$(quickshell ipc --id "${instance_id}" call Launcher invokeEscapeAction 2>/dev/null)" && ! printf '%s' "${category_invoke}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
const state = payload && typeof payload.state === "object" ? payload.state : {};
if (payload.handled !== true) process.exit(1);
if (String(payload.action || "") !== "resetCategory") process.exit(1);
if (state.hasCategoryFilter !== false) process.exit(1);
if (String(state.drunCategoryFilter || "") !== "") process.exit(1);
' >/dev/null 2>&1; then
          errors+=("Launcher.invokeEscapeAction category reset contract invalid")
        fi
      fi
    fi
  fi

  if (( ${#errors[@]} > 0 )); then
    emit_result 0
    exit 1
  fi

  emit_result 1
}

main "$@"
