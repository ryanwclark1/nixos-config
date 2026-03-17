#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
config_root="$(CDPATH= cd -- "${script_dir}/../config" >/dev/null && pwd)"
launcher_qml="${script_dir}/../config/launcher/Launcher.qml"
launcher_search_field_qml="${script_dir}/../config/launcher/LauncherSearchField.qml"
launcher_settings_qml="${script_dir}/../config/menu/settings/tabs/ShellCoreSectionTab.qml"
expected_config="$(realpath "${script_dir}/../config/shell.qml" 2>/dev/null || printf '%s' "${script_dir}/../config/shell.qml")"
apps_helper="${script_dir}/apps.sh"

source "${script_dir}/runtime-warning-filter.sh"

instance_id=""
ci_mode=0
repo_shell_mode=0
repo_shell_pid=""
repo_shell_service_was_active=0
repo_shell_env=()
violations=()
pass_count=0
warn_count=0
fail_count=0

usage() {
  cat <<'EOF'
Usage: check-launcher-responsive.sh [--id INSTANCE_ID] [--repo-shell] [--ci]

Validates launcher responsive guardrails by:
  - checking static compact/tight layout invariants in Launcher.qml/ShellCoreSectionTab.qml,
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

require_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! rg -n -U --multiline --pcre2 -- "$pattern" "$file" >/dev/null 2>&1; then
    violations+=("${label} missing in ${file}")
  fi
}

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
  local line key value
  repo_shell_env=()
  repo_shell_env+=("PATH=${script_dir}:${PATH}")
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
  env "${repo_shell_env[@]}" quickshell -p "${config_root}/shell.qml" >/tmp/quickshell-repo-launcher-responsive.log 2>&1 &
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
  printf 'Repo shell did not become IPC-ready in time. See /tmp/quickshell-repo-launcher-responsive.log\n' >&2
  exit 1
}

discover_reachable_instance() {
  local candidate show_output log_file launch_line
  local fallback_candidate="" drun_candidate="" escape_candidate="" config_candidate="" preferred_candidate=""
  if [[ ! -d "${runtime_root}" ]]; then
    return 1
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

call_ipc() {
  local target="$1"
  local action="$2"
  shift 2
  quickshell ipc --id "${instance_id}" call "${target}" "${action}" "$@"
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
  require_literal "$launcher_qml" 'width: Math.min(1120, Math.max(launcherRoot.sidebarCompact ? 380 : 460, launcherRoot.usableWidth - (launcherRoot.tightMode ? 24 : 40)))' "responsive launcher width bounds"
  require_literal "$launcher_qml" 'height: Math.min(980, Math.max(520, launcherRoot.usableHeight - (launcherRoot.tightMode ? 24 : 28)))' "responsive launcher height bounds"
  require_literal "$launcher_search_field_qml" 'height: 48' "compact search bar height"
  require_literal "$launcher_qml" 'visible: launcherRoot.transientNoticeText !== "" && !launcherRoot.tightMode' "transient notice tight-mode guard"
  require_literal "$launcher_qml" 'visible: Config.launcherShowRuntimeMetrics && !launcherRoot.tightMode' "runtime metrics tight-mode guard"
  require_literal "$launcher_qml" 'loadState: String(modeLoadState || "idle"),' "launcher state load-state payload"
  require_literal "$launcher_qml" 'allItemCount: allItems.length,' "launcher state all-item payload"
  require_literal "$launcher_qml" 'filteredItemCount: filteredItems.length,' "launcher state filtered-item payload"
  require_pattern "$launcher_qml" 'function drunCategoryState\(\)\s*(?::\s*string)?\s*\{\s*return JSON\.stringify\(launcherRoot\.drunCategoryStateObject\(\)\);\s*\}' "drun category IPC payload mapping"
  require_pattern "$launcher_qml" 'function escapeActionState\(\)\s*(?::\s*string)?\s*\{\s*return JSON\.stringify\(launcherRoot\.escapeActionStateObject\(\)\);\s*\}' "escape action IPC payload mapping"
  require_pattern "$launcher_qml" 'function diagnosticSetSearchText\(text(?::\s*string)?\)\s*(?::\s*string)?\s*\{\s*return launcherRoot\.diagnosticSetSearchText\(text\);\s*\}' "escape action query setter IPC mapping"
  require_pattern "$launcher_qml" 'function diagnosticSetDrunCategoryFilter\(categoryKey(?::\s*string)?\)\s*(?::\s*string)?\s*\{\s*return launcherRoot\.diagnosticSetDrunCategoryFilter\(categoryKey\);\s*\}' "escape action category setter IPC mapping"
  require_pattern "$launcher_qml" 'function diagnosticSetViewport\(widthValue(?::\s*real)?\s*,\s*heightValue(?::\s*real)?\)\s*(?::\s*string)?\s*\{\s*return launcherRoot\.diagnosticSetViewport\(widthValue,\s*heightValue\);\s*\}' "viewport override IPC mapping"
  require_pattern "$launcher_qml" 'function invokeEscapeAction\(\)\s*(?::\s*string)?\s*\{' "escape action invoker IPC mapping"
  require_literal "$launcher_qml" 'function escapeActionStateObject() {' "escape action payload helper"
  require_literal "$launcher_qml" 'diagnosticSetViewport(0, 0);' "diagnostic viewport reset"
  require_literal "$launcher_qml" 'visible: launcherRoot.showLauncherHome && launcherRoot.drunCategoryFiltersEnabled && launcherRoot.mode === "drun" && launcherRoot.drunCategoryOptions.length > 1' "drun category chip visibility guard"
  require_literal "$launcher_settings_qml" 'minimumHeight: root.compactMode ? 76 : 44' "settings compact row height"
  require_literal "$launcher_settings_qml" 'elide: root.compactMode ? Text.ElideNone : Text.ElideRight' "settings compact label wrapping"
  require_literal "$launcher_settings_qml" 'wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap' "settings compact wrap mode"

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

  local data_state
  if launcher_state="$(call_ipc Launcher launcherState 2>/dev/null)" && printf '%s' "${launcher_state}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
if (String(payload.mode || "") !== "drun") process.exit(1);
if (String(payload.loadState || "") !== "ready") process.exit(1);
if (!(Number(payload.allItemCount || 0) > 0)) process.exit(1);
' >/dev/null 2>&1; then
    pass "Launcher.openDrun populates application results"
  else
    fail "Launcher.openDrun populates application results"
    if [[ -n "${launcher_state:-}" ]]; then
      printf '%s\n' "${launcher_state}" >&2
    fi
  fi

  local launcher_state
  if launcher_action_available "launcherState" && launcher_state="$(call_ipc Launcher launcherState 2>/dev/null)" && printf '%s' "${launcher_state}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
const viewportWidth = Number(payload.viewportWidth || 0);
const viewportHeight = Number(payload.viewportHeight || 0);
const usableWidth = Number(payload.usableWidth || 0);
const usableHeight = Number(payload.usableHeight || 0);
const hudWidth = Number(payload.hudWidth || 0);
const hudHeight = Number(payload.hudHeight || 0);
if (!(viewportWidth > 0 && viewportHeight > 0)) process.exit(1);
if (!(usableWidth > 0 && usableHeight > 0)) process.exit(1);
if (!(hudWidth >= 460 && hudHeight >= 520)) process.exit(1);
if (usableWidth >= 1400 && !(hudWidth >= 1000)) process.exit(1);
' >/dev/null 2>&1; then
    pass "Launcher.launcherState viewport sizing invariants"
  else
    fail "Launcher.launcherState viewport sizing invariants"
    if [[ -n "${launcher_state:-}" ]]; then
      printf '%s\n' "${launcher_state}" >&2
    fi
  fi

  if call_ipc Launcher openFiles >/dev/null 2>&1 && call_ipc Launcher diagnosticSetSearchText "/nixos" >/dev/null 2>&1; then
    local files_ready=0 files_attempt
    for files_attempt in $(seq 1 60); do
      data_state="$(call_ipc Launcher launcherState 2>/dev/null || true)"
      if [[ -n "${data_state}" ]] && printf '%s' "${data_state}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
if (String(payload.mode || "") !== "files") process.exit(1);
if (String(payload.searchText || "") !== "/nixos") process.exit(1);
if (String(payload.loadState || "") !== "ready") process.exit(1);
if (!(Number(payload.filteredItemCount || 0) > 0)) process.exit(1);
' >/dev/null 2>&1; then
        files_ready=1
        break
      fi
      sleep 0.5
    done
    if (( files_ready == 1 )); then
      pass "Launcher.files query reaches ready state with results"
    else
      fail "Launcher.files query reaches ready state with results"
      if [[ -n "${data_state:-}" ]]; then
        printf '%s\n' "${data_state}" >&2
      fi
    fi
  else
    fail "Launcher.files query probe setup"
  fi

  if call_ipc Launcher openDrun >/dev/null 2>&1; then
    pass "Launcher.openDrun for category diagnostics"
  else
    fail "Launcher.openDrun for category diagnostics"
  fi

  if [[ -f "${apps_helper}" ]]; then
    local app_probe duration_ms app_count
    app_probe="$(node -e 'const {spawnSync} = require("node:child_process"); const helper = process.argv[1]; const started = Date.now(); const result = spawnSync("bash", [helper], {encoding:"utf8"}); if (result.status !== 0) process.exit(result.status || 1); const took = Date.now() - started; let payload = []; try { payload = JSON.parse(result.stdout || "[]"); } catch (error) { process.exit(2); } process.stdout.write(String(took) + "\n" + String(Array.isArray(payload) ? payload.length : 0));' "${apps_helper}" 2>/dev/null || true)"
    duration_ms="$(printf '%s\n' "${app_probe}" | head -n 1)"
    app_count="$(printf '%s\n' "${app_probe}" | tail -n 1)"
    if [[ "${duration_ms}" =~ ^[0-9]+$ ]] && [[ "${app_count}" =~ ^[0-9]+$ ]] && (( duration_ms <= 2000 )) && (( app_count > 0 )); then
      pass "apps helper populates quickly (${duration_ms}ms, ${app_count} apps)"
    else
      fail "apps helper populates quickly"
      printf 'apps helper probe: duration_ms=%s count=%s path=%s\n' "${duration_ms:-<none>}" "${app_count:-<none>}" "${apps_helper}" >&2
    fi
  else
    warn "apps helper missing; skipping launcher app helper timing probe"
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
    if [[ -z "${category_state}" ]]; then
      warn "Launcher.drunCategoryState returned empty payload in live instance; restart QuickShell to validate category-chip invariants"
    elif printf '%s' "${category_state}" | node -e '
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
      warn "Launcher.drunCategoryState payload not parseable in live instance; restart QuickShell to validate category-chip invariants"
      printf '%s\n' "${category_state}" >&2
    fi
  else
    fail "Launcher.drunCategoryState IPC call failed"
  fi

  if ! launcher_action_available "escapeActionState"; then
    if call_ipc Shell reloadConfig >/dev/null 2>&1; then
      sleep 1
    fi
  fi
  if ! launcher_action_available "escapeActionState" || ! launcher_action_available "diagnosticSetSearchText" || ! launcher_action_available "diagnosticSetDrunCategoryFilter" || ! launcher_action_available "invokeEscapeAction"; then
    warn "Launcher escape diagnostics not exposed by live instance after reload; restart QuickShell to validate Esc reset ordering"
  else
    local escape_state query_set query_invoke category_key category_set category_invoke
    if escape_state="$(call_ipc Launcher escapeActionState 2>/dev/null)" && printf '%s' "${escape_state}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
if (String(payload.action || "") !== "close") process.exit(1);
' >/dev/null 2>&1; then
      pass "Launcher.escapeActionState default close branch"
    else
      fail "Launcher.escapeActionState default close branch"
    fi

    if query_set="$(call_ipc Launcher diagnosticSetSearchText "__launcher_escape_probe__" 2>/dev/null)" && printf '%s' "${query_set}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
if (String(payload.action || "") !== "resetQuery") process.exit(1);
if (payload.hasQuery !== true) process.exit(1);
if (String(payload.searchText || "") !== "__launcher_escape_probe__") process.exit(1);
' >/dev/null 2>&1; then
      pass "Launcher.escapeActionState query reset branch"
    else
      fail "Launcher.escapeActionState query reset branch"
    fi

    if query_invoke="$(call_ipc Launcher invokeEscapeAction 2>/dev/null)" && printf '%s' "${query_invoke}" | node -e '
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
      pass "Launcher.invokeEscapeAction clears query before close"
    else
      fail "Launcher.invokeEscapeAction clears query before close"
    fi

    category_key="$(printf '%s' "${category_state:-}" | node -e '
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
      if category_set="$(call_ipc Launcher diagnosticSetDrunCategoryFilter "${category_key}" 2>/dev/null)" && printf '%s' "${category_set}" | node -e '
const fs = require("node:fs");
const raw = fs.readFileSync(0, "utf8").trim();
let payload = JSON.parse(raw);
if (typeof payload === "string") payload = JSON.parse(payload);
const state = payload && typeof payload.state === "object" ? payload.state : {};
if (state.hasCategoryFilter !== true) process.exit(1);
if (String(state.action || "") !== "resetCategory") process.exit(1);
' >/dev/null 2>&1; then
        pass "Launcher.escapeActionState category reset branch"
      else
        fail "Launcher.escapeActionState category reset branch"
      fi

      if category_invoke="$(call_ipc Launcher invokeEscapeAction 2>/dev/null)" && printf '%s' "${category_invoke}" | node -e '
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
        pass "Launcher.invokeEscapeAction clears category before close"
      else
        fail "Launcher.invokeEscapeAction clears category before close"
      fi
    else
      pass "Launcher escape category probe skipped: no non-All drun category option available"
    fi
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
    filtered="$(runtime_filter_log_delta launcher "${delta_file}")"
    if runtime_log_contains_actionable_text "${filtered}"; then
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

  if (( repo_shell_mode == 1 )); then
    trap cleanup_repo_shell EXIT
    start_repo_shell
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
