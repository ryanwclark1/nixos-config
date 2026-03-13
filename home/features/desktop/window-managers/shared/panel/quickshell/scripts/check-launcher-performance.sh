#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
launcher_qml="${script_dir}/../config/launcher/Launcher.qml"
system_tab_qml="${script_dir}/../config/menu/settings/tabs/SystemTab.qml"

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

require_literal "$launcher_qml" 'filterRuns: 0,' "filter metric counter"
require_literal "$launcher_qml" 'lastFilterMs: 0,' "last filter metric field"
require_literal "$launcher_qml" 'avgFilterMs: 0,' "average filter metric field"
require_literal "$launcher_qml" 'filesFdLoads: 0,' "files fd backend metric field"
require_literal "$launcher_qml" 'filesFindLoads: 0,' "files find backend metric field"
require_literal "$launcher_qml" 'filesFdLastMs: 0,' "files fd last latency metric field"
require_literal "$launcher_qml" 'filesFindLastMs: 0,' "files find last latency metric field"
require_literal "$launcher_qml" 'filesFdAvgMs: 0,' "files fd average latency metric field"
require_literal "$launcher_qml" 'filesFindAvgMs: 0,' "files find average latency metric field"
require_literal "$launcher_qml" 'filesResolveRuns: 0,' "files backend resolve run metric field"
require_literal "$launcher_qml" 'filesResolveLastMs: 0,' "files backend resolve last latency metric field"
require_literal "$launcher_qml" 'filesResolveAvgMs: 0,' "files backend resolve average latency metric field"
require_literal "$launcher_qml" 'property int fileSearchBackendResolvedAt: 0' "files backend resolved timestamp cache field"
require_literal "$launcher_qml" 'readonly property int fileSearchBackendRefreshMs: 180000' "files backend refresh interval field"
require_literal "$launcher_qml" 'readonly property int fileSearchBackendMissRefreshMs: 20000' "files backend miss refresh interval field"
require_literal "$launcher_qml" 'readonly property string filesCacheStatsLabel: {' "files cache stats label property"
require_literal "$launcher_qml" 'function recordFilterMetric(durationMs) {' "filter metric recorder"
require_literal "$launcher_qml" 'function recordFilesBackendLoad(backend, durationMs) {' "files backend metric recorder"
require_literal "$launcher_qml" 'function recordFilesBackendResolveMetric(durationMs) {' "files backend resolve metric recorder"
require_literal "$launcher_qml" 'function invalidateCommandAvailability(cmd) {' "command availability invalidation helper"
require_literal "$launcher_qml" 'function showTransientNotice(message, durationMs) {' "launcher transient notice helper"
require_literal "$launcher_qml" 'property string transientNoticeText: ""' "launcher transient notice property"
require_literal "$launcher_qml" 'function filesBackendStatusObject() {' "files backend status payload helper"
require_literal "$launcher_qml" 'function forceRedetectFileSearchBackend(announce, callback) {' "manual files backend redetect helper"
require_literal "$launcher_qml" 'function diagnosticReset() {' "launcher diagnostic reset helper"
require_literal "$launcher_qml" 'function redetectFilesBackend() { launcherRoot.forceRedetectFileSearchBackend(true, function(_) {}); }' "files backend redetect IPC action"
require_literal "$launcher_qml" 'function diagnosticReset() { launcherRoot.diagnosticReset(); }' "launcher diagnostic reset IPC action"
require_literal "$launcher_qml" 'function filesBackendStatus() { return JSON.stringify(launcherRoot.filesBackendStatusObject()); }' "files backend status IPC action"
require_literal "$launcher_qml" 'recordFilterMetric(Date.now() - startedAt);' "filter metric recording call"
require_literal "$launcher_qml" 'recordFilesBackendLoad(backend, tookMs);' "files backend metric recording call"
require_literal "$launcher_qml" 'recordFilesBackendResolveMetric(Date.now() - startedAt);' "files backend resolve metric recording call"
require_literal "$launcher_qml" 'invalidateCommandAvailability("fd");' "files backend fd cache invalidation call"
require_literal "$launcher_qml" 'invalidateCommandAvailability("find");' "files backend find cache invalidation call"
require_literal "$launcher_qml" 'showTransientNotice("Files backend re-detected: " + backend, 2600);' "files backend redetect feedback notice"
require_literal "$launcher_qml" 'showTransientNotice("Launcher diagnostics reset", 2200);' "launcher diagnostic reset feedback notice"
require_literal "$launcher_qml" 'function fuzzyMatchLower(s, p) {' "lowercased fuzzy matcher"
require_literal "$launcher_qml" 'function rankItem(item, clean, cleanLower) {' "rank function with precomputed query"
require_literal "$launcher_qml" 'var cleanLower = clean.toLowerCase();' "single query lowercase preparation"
require_literal "$launcher_qml" 'fuzzyMatchLower(name, cleanLower)' "rank uses lowered matcher"
require_literal "$launcher_qml" '+ " • filter avg " + (launcherRoot.launcherMetrics.avgFilterMs || 0) + "ms"' "runtime metrics filter average display"
require_literal "$launcher_qml" '+ " / last " + (launcherRoot.launcherMetrics.lastFilterMs || 0) + "ms"' "runtime metrics filter last display"
require_literal "$launcher_qml" '+ " • fd/find " + (launcherRoot.launcherMetrics.filesFdLoads || 0) + "/"' "runtime metrics files backend counter display"
require_literal "$launcher_qml" '+ " • fd " + (launcherRoot.launcherMetrics.filesFdAvgMs || 0) + "/" + (launcherRoot.launcherMetrics.filesFdLastMs || 0) + "ms"' "runtime metrics fd latency display"
require_literal "$launcher_qml" '+ " • find " + (launcherRoot.launcherMetrics.filesFindAvgMs || 0) + "/" + (launcherRoot.launcherMetrics.filesFindLastMs || 0) + "ms"' "runtime metrics find latency display"
require_literal "$launcher_qml" '+ " • resolve " + (launcherRoot.launcherMetrics.filesResolveAvgMs || 0) + "/" + (launcherRoot.launcherMetrics.filesResolveLastMs || 0) + "ms"' "runtime metrics resolve latency display"
require_literal "$launcher_qml" '+ (launcherRoot.mode === "files" ? (" • cache " + launcherRoot.filesCacheStatsLabel) : "")' "runtime metrics files cache stats display"
require_literal "$system_tab_qml" 'label: "Re-detect Files Backend"' "settings button label for files backend redetect"
require_literal "$system_tab_qml" 'onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "redetectFilesBackend"])' "settings redetect files backend action binding"
require_literal "$system_tab_qml" 'label: "Launcher Diagnostic Reset"' "settings button label for launcher diagnostic reset"
require_literal "$system_tab_qml" 'onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "diagnosticReset"])' "settings launcher diagnostic reset action binding"
forbid_literal "$launcher_qml" 'function fuzzyMatch(str, pattern) {' "legacy fuzzy matcher signature"

if (( ${#violations[@]} > 0 )); then
  printf '%s\n' "Launcher performance check failed:" >&2
  printf '  - %s\n' "${violations[@]}" >&2
  exit 1
fi

printf '%s\n' "Launcher performance check passed."
