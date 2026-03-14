#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
reference_dir="${script_dir}/../examples/plugins/reference-local-toolkit"
state_fixture="${reference_dir}/expected-state-envelope.json"
settings_fixture="${reference_dir}/expected-settings.json"
manifest="${reference_dir}/manifest.json"
bar_widget="${reference_dir}/BarWidget.qml"
launcher_provider="${reference_dir}/LauncherProvider.qml"
settings_view="${reference_dir}/Settings.qml"

pass_count=0
fail_count=0

pass() {
  printf '[PASS] %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if rg -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  echo '[FAIL] jq is required for reference plugin fixture checks' >&2
  exit 1
fi

for required in "$state_fixture" "$settings_fixture" "$manifest" "$bar_widget" "$launcher_provider" "$settings_view"; do
  if [[ ! -f "$required" ]]; then
    echo "[FAIL] Missing reference plugin file: ${required}" >&2
    exit 1
  fi
done

state_version="$(jq -r '.metadata.stateVersion' "$manifest")"

if jq -e --argjson version "$state_version" '
  .stateVersion == $version
  and (.updatedAt | type == "string")
  and (.payload | type == "object")
  and (.payload.count | type == "number")
  and (.payload.count >= 0)
  and (.payload.lastUpdated | type == "string")
  and ((.payload | keys | sort) == ["count", "lastUpdated"])
' "$state_fixture" >/dev/null 2>&1; then
  pass "reference state envelope fixture matches the expected persisted payload shape"
else
  fail "reference state envelope fixture drifted from the expected persisted payload shape"
fi

if jq -e '
  (.label | type == "string")
  and (.showUpdated | type == "boolean")
  and (.failureMode == "none" or .failureMode == "query" or .failureMode == "execute")
  and (.lastSummaryQuery | type == "string")
  and ((keys | sort) == ["failureMode", "label", "lastSummaryQuery", "showUpdated"])
' "$settings_fixture" >/dev/null 2>&1; then
  pass "reference settings fixture matches the expected plugin settings keys"
else
  fail "reference settings fixture drifted from the expected plugin settings keys"
fi

require_pattern "$bar_widget" 'loadSetting\("label", "Ref"\)' "reference bar widget reads the label setting"
require_pattern "$bar_widget" 'loadSetting\("showUpdated", false\)' "reference bar widget reads the showUpdated setting"
require_pattern "$bar_widget" 'stateVersion: 2' "reference bar widget persists state version 2"
require_pattern "$launcher_provider" 'saveSetting\("lastSummaryQuery"' "reference launcher provider persists lastSummaryQuery"
require_pattern "$settings_view" 'saveSetting\("showUpdated"' "reference settings view writes showUpdated"
require_pattern "$settings_view" '_cycleSetting\("label"' "reference settings view cycles the label setting"
require_pattern "$settings_view" '_cycleSetting\("failureMode"' "reference settings view cycles the failureMode setting"
require_pattern "$settings_view" 'removeSetting\("lastSummaryQuery"\)' "reference settings reset clears lastSummaryQuery"
require_pattern "$settings_view" 'stateVersion: 2' "reference settings reset rewrites a v2 state envelope"

printf '[INFO] Plugin reference fixture summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
