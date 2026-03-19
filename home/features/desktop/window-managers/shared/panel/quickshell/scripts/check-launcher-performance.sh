#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_dir="${QS_CONFIG_DIR:-${script_dir}/../src}"
launcher_qml="${config_dir}/launcher/Launcher.qml"
launcher_key_handler_qml="${config_dir}/launcher/LauncherKeyHandler.qml"
launcher_home_qml="${config_dir}/launcher/LauncherHome.qml"
launcher_search_js="${config_dir}/launcher/LauncherSearch.js"
launcher_diag_js="${config_dir}/launcher/LauncherDiagnostics.js"
launcher_metrics_js="${config_dir}/launcher/LauncherMetrics.js"
launcher_metrics_box_qml="${config_dir}/launcher/LauncherMetricsBox.qml"
config_qml="${config_dir}/services/Config.qml"
config_persistence_js="${config_dir}/services/config/ConfigPersistence.js"
launcher_settings_qml="${config_dir}/features/settings/components/tabs/ShellLauncherSection.qml"
launcher_helpers_js="${config_dir}/features/settings/components/tabs/ShellCoreHelpers.js"

violations=()

require_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if ! rg -n -F -- "$needle" "$file" >/dev/null 2>&1; then
    violations+=("${label} missing in ${file}")
  fi
}

forbid_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if rg -n -F -- "$needle" "$file" >/dev/null 2>&1; then
    violations+=("${label} should not be present in ${file}")
  fi
}

# Config/state wiring
require_literal "$config_qml" 'property real launcherScoreCategoryWeight: 0.7' "category weight config property"
require_literal "$config_qml" 'property bool launcherDrunCategoryFiltersEnabled: false' "drun category filter enable config property"
require_literal "$config_persistence_js" '["drunCategoryFiltersEnabled", "launcherDrunCategoryFiltersEnabled"]' "drun category filter enable config persistence"
require_literal "$config_persistence_js" '["scoreCategoryWeight", "launcherScoreCategoryWeight"]' "category weight config persistence"
require_literal "$launcher_helpers_js" 'Config.launcherDrunCategoryFiltersEnabled = false;' "settings app category filters reset default"
require_literal "$launcher_helpers_js" 'Config.launcherScoreCategoryWeight = 0.7;' "settings category weight reset default"

# Metrics core
require_literal "$launcher_qml" 'property var launcherMetrics: ({' "launcher metrics state property"
require_literal "$launcher_qml" 'filesResolveAvgMs: 0,' "files backend resolve average latency metric field"
require_literal "$launcher_qml" 'readonly property string filesCacheStatsLabel: {' "files cache stats label property"
require_literal "$launcher_qml" 'function recordFilterMetric(durationMs) {' "filter metric recorder"
require_literal "$launcher_qml" 'function recordFilesBackendLoad(backend, durationMs) {' "files backend metric recorder"
require_literal "$launcher_qml" 'function recordFilesBackendResolveMetric(durationMs) {' "files backend resolve metric recorder"
require_literal "$launcher_qml" 'depChecker.invalidateCommandAvailability("fd");' "files backend fd cache invalidation call"
require_literal "$launcher_qml" 'depChecker.invalidateCommandAvailability("find");' "files backend find cache invalidation call"
require_literal "$launcher_qml" 'recordFilterMetric(Date.now() - startedAt);' "filter metric recording call"
require_literal "$launcher_qml" 'recordFilesBackendLoad("fd", tookMs);' "files fd backend metric recording call"
require_literal "$launcher_qml" 'recordFilesBackendLoad("find", tookMs);' "files find backend metric recording call"
require_literal "$launcher_qml" 'recordFilesBackendResolveMetric(Date.now() - startedAt);' "files backend resolve metric recording call"
require_literal "$launcher_qml" 'showTransientNotice("Files backend re-detected: " + backend, 2600);' "files backend redetect feedback notice"
require_literal "$launcher_qml" 'showTransientNotice("Launcher diagnostics reset", 2200);' "launcher diagnostic reset feedback notice"

require_literal "$launcher_metrics_js" 'function freshMetrics() {' "metrics fresh state helper"
require_literal "$launcher_metrics_js" 'filesFdLoads: 0,' "metrics fresh fd load counter"
require_literal "$launcher_metrics_js" 'filesResolveAvgMs: 0,' "metrics fresh resolve latency field"
require_literal "$launcher_metrics_js" 'function recordFilesBackendLoad(metrics, backend, durationMs) {' "metrics files backend load helper"
require_literal "$launcher_metrics_js" 'function recordFilesBackendResolveMetric(metrics, durationMs) {' "metrics backend resolve helper"
require_literal "$launcher_metrics_js" 'function recordFilterMetric(metrics, durationMs) {' "metrics filter recorder helper"

require_literal "$launcher_diag_js" 'function filesBackendStatusObject(props) {' "files backend diagnostics helper"
require_literal "$launcher_diag_js" 'filesResolveAvgMs: resolveAvgMs,' "files backend status metrics resolve avg field"
require_literal "$launcher_diag_js" 'filesResolveLastMs: resolveLastMs,' "files backend status metrics resolve last field"
require_literal "$launcher_diag_js" 'filesFdLoads: filesFdLoads,' "files backend status metrics fd loads field"
require_literal "$launcher_diag_js" 'filesFindLoads: filesFindLoads,' "files backend status metrics find loads field"
require_literal "$launcher_diag_js" 'hits: fileCacheHits,' "files backend status cache hits field"
require_literal "$launcher_diag_js" 'misses: fileCacheMisses,' "files backend status cache misses field"

require_literal "$launcher_metrics_box_qml" '" • filter avg " + (root.metrics.avgFilterMs || 0) + "ms"' "runtime metrics filter average display"
require_literal "$launcher_metrics_box_qml" '" / last " + (root.metrics.lastFilterMs || 0) + "ms"' "runtime metrics filter last display"
require_literal "$launcher_metrics_box_qml" '" • fd/find " + (root.metrics.filesFdLoads || 0) + "/" + (root.metrics.filesFindLoads || 0)' "runtime metrics files backend counter display"
require_literal "$launcher_metrics_box_qml" '" • fd " + (root.metrics.filesFdAvgMs || 0) + "/" + (root.metrics.filesFdLastMs || 0) + "ms"' "runtime metrics fd latency display"
require_literal "$launcher_metrics_box_qml" '" • find " + (root.metrics.filesFindAvgMs || 0) + "/" + (root.metrics.filesFindLastMs || 0) + "ms"' "runtime metrics find latency display"
require_literal "$launcher_metrics_box_qml" '" • resolve " + (root.metrics.filesResolveAvgMs || 0) + "/" + (root.metrics.filesResolveLastMs || 0) + "ms"' "runtime metrics resolve latency display"
require_literal "$launcher_metrics_box_qml" '(" • cache " + root.filesCacheStatsLabel)' "runtime metrics files cache stats display"

# Search/ranking path
require_literal "$launcher_search_js" 'function fuzzyMatchLower(s, p) {' "lowercased fuzzy matcher"
require_literal "$launcher_search_js" 'function ensureItemRankCache(item) {' "rank cache preparation helper"
require_literal "$launcher_search_js" 'item._primaryCategoryKey = tokens.length > 0 ? tokens[0] : "";' "rank cache primary category key"
require_literal "$launcher_search_js" 'item._categoryKeywordsLower = (category + " " + keywords).trim();' "category keywords cache field"
require_literal "$launcher_search_js" 'function rankItem(item, clean, cleanLower, mode, weights) {' "rank function with precomputed query"
require_literal "$launcher_search_js" 'var categoryScore = mode === "drun" ? (fuzzyMatchLower(item._categoryKeywordsLower, cleanLower) * weights.category) : 0;' "rank drun-only category/keywords score weighting"
require_literal "$launcher_search_js" 'function compareLauncherItemsAlpha(a, b) {' "deterministic launcher item alpha comparator"
require_literal "$launcher_search_js" 'return compareLauncherItemsAlpha(a, b);' "deterministic tie-breaker usage"
require_literal "$launcher_search_js" 'function compareByScoreThenDepth(a, b) {' "deterministic files comparator"
require_literal "$launcher_search_js" 'function compareByScoreThenUsage(a, b) {' "deterministic drun comparator"
require_literal "$launcher_qml" 'category: Config.launcherScoreCategoryWeight' "search category weight wiring"
require_literal "$launcher_qml" 'var cleanLower = clean.toLowerCase();' "single query lowercase preparation"
require_literal "$launcher_qml" 'var bestScore = Search.rankItem(item, clean, cleanLower, mode, _rankWeights);' "rank uses lowered matcher"
require_literal "$launcher_qml" 'scoredItems.sort(Search.compareByScoreThenUsage);' "recent apps deterministic ordering sort"
require_literal "$launcher_qml" 'state.scoredItems.sort(Search.compareByScoreThenDepth);' "files deterministic ordering sort"

# Drun category filtering and keyboard flow
require_literal "$launcher_qml" 'readonly property string drunCategoryFilterLabel: TextHelpers.categoryFilterLabel(drunCategoryOptions, drunCategoryFilter)' "drun category filter label property"
require_literal "$launcher_qml" 'function refreshDrunCategoryOptions(apps) {' "drun category options refresh helper"
require_literal "$launcher_qml" 'function setDrunCategoryFilter(categoryKey) {' "drun category filter setter"
require_literal "$launcher_qml" 'function jumpDrunCategoryBoundary(toEnd) {' "drun category boundary helper"
require_literal "$launcher_qml" 'function selectDrunCategorySlot(slot) {' "drun category filter slot helper"
require_literal "$launcher_qml" 'if (mode === "drun" && drunCategoryFilter !== "" && !itemMatchesDrunCategory(item, drunCategoryFilter))' "drun category filter gating in result list"
require_literal "$launcher_home_qml" 'readonly property bool showCategoryFilters: root.showCategoryFiltersSection && root.launcher.showLauncherHome && root.launcher.drunCategoryFiltersEnabled && root.launcher.mode === "drun" && root.launcher.drunCategoryOptions.length > 1' "drun category chip visibility guard"
require_literal "$launcher_key_handler_qml" 'launcher.drunCategoryFiltersEnabled && launcher.mode === "drun" && (event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.ControlModifier)' "drun category keyboard handling branch"
require_literal "$launcher_key_handler_qml" 'if (event.key === Qt.Key_Left) {' "drun category keyboard left cycling"
require_literal "$launcher_key_handler_qml" 'if (launcher.cycleDrunCategoryFilter(-1))' "drun category left cycle action"
require_literal "$launcher_key_handler_qml" 'if (launcher.cycleDrunCategoryFilter(1))' "drun category right cycle action"
require_literal "$launcher_key_handler_qml" 'else if (event.key === Qt.Key_PageUp) {' "drun category page-up action branch"
require_literal "$launcher_key_handler_qml" 'else if (event.key === Qt.Key_PageDown) {' "drun category page-down action branch"
require_literal "$launcher_key_handler_qml" 'else if (event.key === Qt.Key_Home) {' "drun category home action branch"
require_literal "$launcher_key_handler_qml" 'if (launcher.jumpDrunCategoryBoundary(false))' "drun category home action"
require_literal "$launcher_key_handler_qml" 'else if (event.key === Qt.Key_End) {' "drun category end action branch"
require_literal "$launcher_key_handler_qml" 'if (launcher.jumpDrunCategoryBoundary(true))' "drun category end action"
require_literal "$launcher_key_handler_qml" 'else if (event.key === Qt.Key_0 || event.key === Qt.Key_Backspace) {' "drun category clear action branch"
require_literal "$launcher_key_handler_qml" 'if (launcher.setDrunCategoryFilter(""))' "drun category clear shortcut"
require_literal "$launcher_key_handler_qml" 'if (categorySlot > 0 && launcher.selectDrunCategorySlot(categorySlot))' "drun category numeric slot shortcut"
require_literal "$launcher_key_handler_qml" 'launcher.drunCategoryFiltersEnabled && launcher.mode === "drun" && launcher.showLauncherHome && (event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Tab' "drun category ctrl+tab keyboard handling branch"
require_literal "$launcher_key_handler_qml" 'var direction = (event.modifiers & Qt.ShiftModifier) ? -1 : 1;' "drun category ctrl+tab direction handling"
require_literal "$launcher_key_handler_qml" 'if (launcher.cycleDrunCategoryFilter(direction))' "drun category ctrl+tab cycle action"

# Settings exposure for diagnostics and category weighting
require_literal "$launcher_settings_qml" 'label: "Re-detect Files Backend"' "settings button label for files backend redetect"
require_literal "$launcher_settings_qml" 'onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "redetectFilesBackend"])' "settings redetect files backend action binding"
require_literal "$launcher_settings_qml" 'label: "Launcher Diagnostic Reset"' "settings button label for launcher diagnostic reset"
require_literal "$launcher_settings_qml" 'onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "diagnosticReset"])' "settings launcher diagnostic reset action binding"
require_literal "$launcher_settings_qml" 'label: "Category/Keywords Weight"' "settings category keywords weight slider label"
require_literal "$launcher_settings_qml" 'value: Config.launcherScoreCategoryWeight' "settings category keywords weight slider binding"
require_literal "$launcher_settings_qml" 'onMoved: v => Config.launcherScoreCategoryWeight = v' "settings category keywords weight slider action"
require_literal "$launcher_settings_qml" 'label: "App Category Filters"' "settings app category filters toggle label"
require_literal "$launcher_settings_qml" 'configKey: "launcherDrunCategoryFiltersEnabled"' "settings app category filters toggle binding"

forbid_literal "$launcher_qml" 'function fuzzyMatch(str, pattern) {' "legacy fuzzy matcher signature"

if (( ${#violations[@]} > 0 )); then
  printf '%s\n' "Launcher performance check failed:" >&2
  printf '  - %s\n' "${violations[@]}" >&2
  exit 1
fi

printf '%s\n' "Launcher performance check passed."
