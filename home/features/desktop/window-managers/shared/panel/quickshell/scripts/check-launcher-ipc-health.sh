#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
launcher_qml="${script_dir}/../config/launcher/Launcher.qml"

instance_id=""
ci_mode=0
checked_actions=()
errors=()
status_payload_valid=1

usage() {
  cat <<'EOF'
Usage: check-launcher-ipc-health.sh [--id INSTANCE_ID] [--ci]

Runs a launcher IPC health probe:
  - validates Launcher IPC methods are discoverable,
  - exercises clearMetrics/redetectFilesBackend/diagnosticReset/filesBackendStatus/drunCategoryState,
  - verifies files backend status payload contract literals in Launcher.qml.
In --ci mode, only static contract checks are executed.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      instance_id="${2:-}"
      shift 2
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

discover_reachable_instance() {
  local candidate show_output
  if [[ ! -d "${runtime_root}" ]]; then
    return 1
  fi

  while IFS= read -r candidate; do
    show_output="$(quickshell ipc --id "${candidate}" show 2>/dev/null || true)"
    if [[ -n "${show_output}" ]] && printf '%s' "${show_output}" | rg -q "target Launcher"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done < <(find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -printf '%T@ %f\n' 2>/dev/null | sort -nr | awk '{print $2}')

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

require_literal() {
  local needle="$1"
  local label="$2"
  if ! rg -n -F -- "$needle" "$launcher_qml" >/dev/null 2>&1; then
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

  if (( ${#errors[@]} > 0 )); then
    emit_result 0
    exit 1
  fi

  local action
  for action in clearMetrics redetectFilesBackend diagnosticReset filesBackendStatus drunCategoryState; do
    checked_actions+=("${action}")
  done

  require_literal 'function clearMetrics() { launcherRoot.clearLauncherMetrics(); }' "Launcher.clearMetrics IPC mapping"
  require_literal 'function redetectFilesBackend() { launcherRoot.forceRedetectFileSearchBackend(true, function(_) {}); }' "Launcher.redetectFilesBackend IPC mapping"
  require_literal 'function diagnosticReset() { launcherRoot.diagnosticReset(); }' "Launcher.diagnosticReset IPC mapping"
  require_literal 'function filesBackendStatus() { return JSON.stringify(launcherRoot.filesBackendStatusObject()); }' "Launcher.filesBackendStatus IPC mapping"
  require_literal 'function drunCategoryState() { return JSON.stringify(launcherRoot.drunCategoryStateObject()); }' "Launcher.drunCategoryState IPC mapping"
  require_literal 'function drunCategoryStateObject() {' "drunCategoryState payload helper"
  require_literal 'visible: showLauncherHome && drunCategoryFiltersEnabled && mode === "drun" && normalized.length > 1,' "drunCategoryState visible field"
  require_literal 'activeCount: activeCount,' "drunCategoryState activeCount field"
  require_literal 'totalCount: totalCount,' "drunCategoryState totalCount field"
  require_literal 'options: normalized' "drunCategoryState options field"
  require_literal 'backend: filesBackendLabel,' "backend"
  require_literal 'metrics: ({' "metrics object"
  require_literal 'filesResolveAvgMs: resolveAvgMs,' "metrics.filesResolveAvgMs"
  require_literal 'filesResolveLastMs: resolveLastMs,' "metrics.filesResolveLastMs"
  require_literal 'filesFdLoads: filesFdLoads,' "metrics.filesFdLoads"
  require_literal 'filesFindLoads: filesFindLoads,' "metrics.filesFindLoads"
  require_literal 'cache: ({' "cache object"
  require_literal 'hits: fileCacheHits,' "cache.hits"
  require_literal 'misses: fileCacheMisses,' "cache.misses"

  if (( ci_mode == 1 )); then
    if (( ${#errors[@]} > 0 )); then
      emit_result 0
      exit 1
    fi
    emit_result 1
    exit 0
  fi

  if [[ -z "${instance_id}" ]]; then
    instance_id="$(discover_reachable_instance || true)"
  fi

  if [[ -z "${instance_id}" ]]; then
    errors+=("no reachable quickshell instance found under ${runtime_root}")
    emit_result 0
    exit 1
  fi

  local show_output
  if ! show_output="$(quickshell ipc --id "${instance_id}" show 2>&1)"; then
    errors+=("failed to query IPC metadata for instance ${instance_id}: ${show_output}")
    emit_result 0
    exit 1
  fi

  if ! printf '%s' "${show_output}" | rg -q "target Launcher"; then
    errors+=("Launcher IPC target missing in instance ${instance_id}")
  fi

  for action in "${checked_actions[@]}"; do
    if ! printf '%s' "${show_output}" | rg -q "function ${action}\\("; then
      if [[ "${action}" == "drunCategoryState" ]]; then
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
    if ! quickshell ipc --id "${instance_id}" call Launcher "${action}" >/dev/null 2>&1; then
      if [[ "${action}" == "drunCategoryState" ]]; then
        printf '%s\n' "[WARN] Launcher IPC call failed for ${action} in live instance (restart QuickShell to pick up latest QML)" >&2
        continue
      fi
      errors+=("Launcher IPC call failed: ${action}")
    fi
  done

  if (( ${#errors[@]} > 0 )); then
    emit_result 0
    exit 1
  fi

  emit_result 1
}

main "$@"
