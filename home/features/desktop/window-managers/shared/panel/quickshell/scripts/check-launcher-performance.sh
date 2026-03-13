#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
launcher_qml="${script_dir}/../config/launcher/Launcher.qml"

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
require_literal "$launcher_qml" 'function recordFilterMetric(durationMs) {' "filter metric recorder"
require_literal "$launcher_qml" 'function recordFilesBackendLoad(backend) {' "files backend metric recorder"
require_literal "$launcher_qml" 'recordFilterMetric(Date.now() - startedAt);' "filter metric recording call"
require_literal "$launcher_qml" 'recordFilesBackendLoad(backend);' "files backend metric recording call"
require_literal "$launcher_qml" 'function fuzzyMatchLower(s, p) {' "lowercased fuzzy matcher"
require_literal "$launcher_qml" 'function rankItem(item, clean, cleanLower) {' "rank function with precomputed query"
require_literal "$launcher_qml" 'var cleanLower = clean.toLowerCase();' "single query lowercase preparation"
require_literal "$launcher_qml" 'fuzzyMatchLower(name, cleanLower)' "rank uses lowered matcher"
require_literal "$launcher_qml" '+ " • filter avg " + (launcherRoot.launcherMetrics.avgFilterMs || 0) + "ms"' "runtime metrics filter average display"
require_literal "$launcher_qml" '+ " / last " + (launcherRoot.launcherMetrics.lastFilterMs || 0) + "ms"' "runtime metrics filter last display"
require_literal "$launcher_qml" '+ " • fd/find " + (launcherRoot.launcherMetrics.filesFdLoads || 0) + "/"' "runtime metrics files backend counter display"
forbid_literal "$launcher_qml" 'function fuzzyMatch(str, pattern) {' "legacy fuzzy matcher signature"

if (( ${#violations[@]} > 0 )); then
  printf '%s\n' "Launcher performance check failed:" >&2
  printf '  - %s\n' "${violations[@]}" >&2
  exit 1
fi

printf '%s\n' "Launcher performance check passed."
