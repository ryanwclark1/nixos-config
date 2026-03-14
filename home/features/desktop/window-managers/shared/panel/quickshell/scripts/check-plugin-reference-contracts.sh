#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
reference_dir="${script_dir}/../examples/plugins/reference-local-toolkit"
manifest="${reference_dir}/manifest.json"
bar_widget="${reference_dir}/BarWidget.qml"
launcher_provider="${reference_dir}/LauncherProvider.qml"
settings_view="${reference_dir}/Settings.qml"
reference_readme="${reference_dir}/README.md"

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
  echo '[FAIL] jq is required for reference plugin contract checks' >&2
  exit 1
fi

for required in "$manifest" "$bar_widget" "$launcher_provider" "$settings_view" "$reference_readme"; do
  if [[ ! -f "$required" ]]; then
    echo "[FAIL] Missing reference plugin file: ${required}" >&2
    exit 1
  fi
done

if jq -e '
  .id == "reference.local.toolkit"
  and .type == "multi"
  and .launcher.trigger == "!ref"
  and .launcher.noTrigger == true
  and .metadata.stateVersion == 2
  and (.permissions | sort == ["settings_read","settings_write","state_read","state_write"])
  and .entryPoints.barWidget == "BarWidget.qml"
  and .entryPoints.launcherProvider == "LauncherProvider.qml"
  and .entryPoints.settings == "Settings.qml"
' "$manifest" >/dev/null 2>&1; then
  pass "reference plugin manifest matches the expected local multi-plugin contract"
else
  fail "reference plugin manifest drifted from the expected local multi-plugin contract"
fi

require_pattern "$bar_widget" 'migrateState\(2' "reference bar widget migrates state to v2"
require_pattern "$bar_widget" 'loadStateEnvelope\(' "reference bar widget reads the state envelope"
require_pattern "$bar_widget" 'saveStateEnvelope\(' "reference bar widget persists the state envelope"
require_pattern "$bar_widget" 'incrementCount\(' "reference bar widget exposes an increment interaction"
require_pattern "$bar_widget" 'onPluginRuntimeUpdated' "reference bar widget refreshes from plugin runtime updates"

require_pattern "$launcher_provider" 'function items\(' "reference launcher provider exposes items()"
require_pattern "$launcher_provider" 'function execute\(' "reference launcher provider exposes execute()"
require_pattern "$launcher_provider" '_failureMode\(' "reference launcher provider supports failure-mode diagnostics"
require_pattern "$launcher_provider" '"increment"' "reference launcher provider exposes increment action"
require_pattern "$launcher_provider" '"reset"' "reference launcher provider exposes reset action"
require_pattern "$launcher_provider" '"summary"' "reference launcher provider exposes summary action"
require_pattern "$launcher_provider" 'Reference plugin query failure requested' "reference launcher provider can trigger query degradation"
require_pattern "$launcher_provider" 'Reference plugin execute failure requested' "reference launcher provider can trigger execute degradation"

require_pattern "$settings_view" 'Cycle Label' "reference settings view can cycle the display label"
require_pattern "$settings_view" 'Show Updated Marker' "reference settings view can toggle the updated marker"
require_pattern "$settings_view" 'Failure Mode:' "reference settings view exposes launcher failure mode controls"
require_pattern "$settings_view" 'Reset Plugin State \+ Settings' "reference settings view exposes a full reset action"
require_pattern "$settings_view" 'removeSetting\("failureMode"\)' "reference settings reset clears the failure mode"
require_pattern "$settings_view" 'saveStateEnvelope\(' "reference settings reset rewrites the state envelope"

require_pattern "$reference_readme" '!ref' "reference plugin README documents the launcher trigger"
require_pattern "$reference_readme" 'plugin-local\.sh install-reference' "reference plugin README documents install-reference"
require_pattern "$reference_readme" 'plugin-local\.sh smoke-reference' "reference plugin README documents smoke-reference"
require_pattern "$reference_readme" 'plugin-local\.sh remove-reference' "reference plugin README documents remove-reference"

printf '[INFO] Plugin reference contract summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
