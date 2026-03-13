#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
launcher_qml="${script_dir}/../config/launcher/Launcher.qml"
system_tab_qml="${script_dir}/../config/menu/settings/tabs/SystemTab.qml"

instance_id=""
ci_mode=0
violations=()
pass_count=0
warn_count=0
fail_count=0

usage() {
  cat <<'EOF'
Usage: check-launcher-responsive.sh [--id INSTANCE_ID] [--ci]

Validates launcher responsive guardrails by:
  - checking static compact/tight layout invariants in Launcher.qml/SystemTab.qml,
  - exercising launcher open flows in a live QuickShell instance,
  - scanning fresh log output for warnings/errors.
In --ci mode, only static checks are executed.
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

require_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if ! rg -n -F -- "$needle" "$file" >/dev/null 2>&1; then
    violations+=("${label} missing in ${file}")
  fi
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 2
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

call_ipc() {
  local target="$1"
  local action="$2"
  quickshell ipc --id "${instance_id}" call "${target}" "${action}"
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

static_checks() {
  require_literal "$launcher_qml" 'readonly property bool compactMode: usableWidth < 900 || usableHeight < 640' "compact mode threshold"
  require_literal "$launcher_qml" 'readonly property bool sidebarCompact: usableWidth < 720' "sidebar compact threshold"
  require_literal "$launcher_qml" 'readonly property bool tightMode: usableWidth < 560 || usableHeight < 500' "tight mode threshold"
  require_literal "$launcher_qml" 'width: Math.min(960, Math.max(launcherRoot.sidebarCompact ? 360 : 420, launcherRoot.usableWidth - (launcherRoot.tightMode ? 24 : 40)))' "responsive launcher width bounds"
  require_literal "$launcher_qml" 'height: launcherRoot.compactMode ? 50 : 55' "compact search bar height"
  require_literal "$launcher_qml" 'visible: launcherRoot.transientNoticeText !== "" && !launcherRoot.tightMode' "transient notice tight-mode guard"
  require_literal "$launcher_qml" 'visible: Config.launcherShowRuntimeMetrics && !launcherRoot.tightMode' "runtime metrics tight-mode guard"
  require_literal "$launcher_qml" 'function drunCategoryState() { return JSON.stringify(launcherRoot.drunCategoryStateObject()); }' "drun category IPC payload mapping"
  require_literal "$launcher_qml" 'visible: launcherRoot.showLauncherHome && launcherRoot.drunCategoryFiltersEnabled && launcherRoot.mode === "drun" && launcherRoot.drunCategoryOptions.length > 1' "drun category chip visibility guard"
  require_literal "$system_tab_qml" 'minimumHeight: root.compactMode ? 76 : 44' "settings compact row height"
  require_literal "$system_tab_qml" 'elide: root.compactMode ? Text.ElideNone : Text.ElideRight' "settings compact label wrapping"
  require_literal "$system_tab_qml" 'wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap' "settings compact wrap mode"

  if (( ${#violations[@]} > 0 )); then
    local violation
    for violation in "${violations[@]}"; do
      fail "${violation}"
    done
  else
    pass "Static launcher responsive guardrails present"
  fi
}

runtime_checks() {
  local instance_dir log_file start_bytes=0 delta_file filtered
  instance_dir="${runtime_root}/${instance_id}"
  log_file="${instance_dir}/log.log"
  delta_file="$(mktemp)"
  trap "rm -f '${delta_file}'" EXIT

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
  else
    fail "Shell.reloadConfig"
  fi

  local action
  for action in openDrun openWeb openFiles openSystem toggle; do
    if call_ipc Launcher "${action}" >/dev/null 2>&1; then
      pass "Launcher.${action}"
    else
      fail "Launcher.${action}"
    fi
  done

  if call_ipc Launcher openDrun >/dev/null 2>&1; then
    pass "Launcher.openDrun for category state probe"
  else
    fail "Launcher.openDrun for category state probe"
  fi

  local category_state
  if ! launcher_action_available "drunCategoryState"; then
    # Try to refresh stale QML on long-running sessions before downgrading to warning.
    if call_ipc Shell reloadConfig >/dev/null 2>&1; then
      sleep 1
    fi
  fi
  if ! launcher_action_available "drunCategoryState"; then
    warn "Launcher.drunCategoryState not exposed by live instance after reload; restart QuickShell to validate category-chip invariants"
  elif category_state="$(call_ipc Launcher drunCategoryState 2>/dev/null)"; then
    if printf '%s' "${category_state}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
let payload = null;
try {
  payload = JSON.parse(raw);
} catch (error) {
  console.error("category state is not valid JSON");
  process.exit(1);
}
if (typeof payload === "string") {
  try {
    payload = JSON.parse(payload);
  } catch (error) {}
}
const errors = [];
const options = Array.isArray(payload.options) ? payload.options : [];
const enabled = payload.enabled === true;
const visible = payload.visible === true;
const activeKey = String(payload.activeKey || "");
const activeCount = Number(payload.activeCount || 0);
const totalCount = Number(payload.totalCount || 0);
if (String(payload.mode || "") !== "drun") errors.push("mode must be drun during category probe");
if (options.length < 1) errors.push("options must include at least All");
if (options.length > 0 && String((options[0] || {}).key || "") !== "") errors.push("first option must be All key");
const selected = options.filter((item) => item && item.selected === true);
if (selected.length !== 1) errors.push("exactly one category option must be selected");
if (selected.length === 1 && String(selected[0].key || "") !== activeKey) errors.push("activeKey must match selected option");
if (selected.length === 1 && Number(selected[0].count || 0) !== activeCount) errors.push("activeCount must match selected option badge");
if (activeCount < 0 || totalCount < 0 || activeCount > totalCount) errors.push("activeCount must be within totalCount bounds");
if (!enabled) {
  if (visible) errors.push("chips must not be visible when category filters are disabled");
  if (options.length !== 1) errors.push("disabled category filters must expose only All option");
  if (activeKey !== "") errors.push("disabled category filters must keep activeKey empty");
} else {
  const expectedVisible = payload.showLauncherHome === true && options.length > 1;
  if (visible !== expectedVisible) errors.push("visible must match showLauncherHome + option count");
}
if (errors.length > 0) {
  for (const err of errors) console.error(err);
  process.exit(1);
}
' >/dev/null 2>&1; then
      pass "Launcher.drunCategoryState invariants"
    else
      fail "Launcher.drunCategoryState invariants"
      printf '%s\n' "${category_state}" >&2
    fi
  else
    fail "Launcher.drunCategoryState IPC call failed"
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
    filtered="$(grep -Evi 'qt\.qpa\.wayland\.textinput|qt\.svg: .*Could not resolve property' "${delta_file}" || true)"
    if [[ -n "${filtered}" ]] && printf '%s' "${filtered}" | grep -Eqi 'warn|error|exception|binding loop|ReferenceError|TypeError|failed'; then
      fail "New runtime warnings/errors detected after launcher responsive exercise"
      printf '%s\n' "${filtered}" >&2
    else
      warn "New log output observed, but only known non-blocking warnings were present"
    fi
  else
    pass "No new launcher responsive warnings/errors in runtime log"
  fi
}

main() {
  require_cmd rg
  require_cmd grep
  require_cmd tail
  require_cmd find
  require_cmd awk
  require_cmd node
  if (( ci_mode == 0 )); then
    require_cmd quickshell
  fi

  static_checks

  if (( ci_mode == 1 )); then
    printf '[INFO] CI mode: skipped live launcher runtime responsive probe.\n'
    printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
    (( fail_count == 0 ))
    return
  fi

  if [[ -z "${instance_id}" ]]; then
    instance_id="$(discover_reachable_instance || true)"
  fi

  if [[ -z "${instance_id}" ]]; then
    fail "No reachable QuickShell instances found under ${runtime_root}"
  else
    runtime_checks
  fi

  printf '[INFO] Manual visual QA still required for wide, laptop, and narrow/portrait layouts.\n'
  printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"
