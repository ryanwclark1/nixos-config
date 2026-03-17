#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
reference_dir="${script_dir}/../examples/plugins/reference-local-toolkit"
recovery_fixture="${reference_dir}/expected-recovery-scenarios.json"
launcher_provider="${reference_dir}/LauncherProvider.qml"
settings_view="${reference_dir}/Settings.qml"
plugin_runtime="${script_dir}/../src/services/PluginRuntime.qml"
runtime_catalog="${script_dir}/../src/plugins/runtime-catalog.json"

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
  echo '[FAIL] jq is required for reference plugin recovery checks' >&2
  exit 1
fi

for required in "$recovery_fixture" "$launcher_provider" "$settings_view" "$plugin_runtime" "$runtime_catalog"; do
  if [[ ! -f "$required" ]]; then
    echo "[FAIL] Missing reference recovery file: ${required}" >&2
    exit 1
  fi
done

if jq -e '
  type == "array"
  and length == 4
  and .[0].name == "healthy-query"
  and .[1].name == "query-failure"
  and .[2].name == "execute-failure"
  and .[3].name == "recovered-query"
  and ([.[].failureMode] == ["none", "query", "execute", "none"])
  and ([.[].operation] == ["query", "query", "execute", "query"])
  and ([.[].expectedState] == ["active", "degraded", "degraded", "active"])
  and ([.[].expectedCode] == ["", "E_LAUNCHER_QUERY", "E_LAUNCHER_EXECUTE", ""])
  and ([.[].expectedMessage] | length == 4)
' "$recovery_fixture" >/dev/null 2>&1; then
  pass "reference recovery fixture covers healthy, query-failure, execute-failure, and recovery phases"
else
  fail "reference recovery fixture drifted from the expected healthy/failure/recovery sequence"
fi

while IFS='|' read -r code state; do
  if jq -e --arg code "$code" --arg state "$state" '
    any(.[]; .expectedCode == $code and .expectedState == $state)
  ' "$recovery_fixture" >/dev/null 2>&1; then
    pass "reference recovery fixture includes ${code} -> ${state}"
  else
    fail "reference recovery fixture is missing ${code} -> ${state}"
  fi
done <<'EOF'
E_LAUNCHER_QUERY|degraded
E_LAUNCHER_EXECUTE|degraded
EOF

if jq -e '.errors.E_LAUNCHER_QUERY.severity == "warn" and .errors.E_LAUNCHER_EXECUTE.severity == "warn" and .states.degraded.severity == "warn" and .states.active.severity == "ok"' "$runtime_catalog" >/dev/null 2>&1; then
  pass "runtime catalog severity matches the reference recovery scenarios"
else
  fail "runtime catalog severity drifted from the reference recovery scenarios"
fi

require_pattern "$launcher_provider" '_failureMode\(\) === "query"' "reference launcher provider throws on query failure mode"
require_pattern "$launcher_provider" '_failureMode\(\) === "execute"' "reference launcher provider throws on execute failure mode"
require_pattern "$launcher_provider" 'Reference plugin query failure requested\.' "reference launcher provider exposes the query failure message"
require_pattern "$launcher_provider" 'Reference plugin execute failure requested\.' "reference launcher provider exposes the execute failure message"
require_pattern "$settings_view" '_cycleSetting\("failureMode", \["none", "query", "execute"\]' "reference settings view cycles through healthy and failure modes"
require_pattern "$settings_view" 'removeSetting\("failureMode"\)' "reference settings reset restores the healthy failure mode"
require_pattern "$plugin_runtime" '_setPluginStatus\(providerId, "active", "", ""\);' "plugin service restores launcher providers to active after successful queries"
require_pattern "$plugin_runtime" '_setPluginStatus\(providerId, "degraded", "E_LAUNCHER_QUERY", String\(e\)\);' "plugin service marks query failures as degraded"
require_pattern "$plugin_runtime" '_setPluginStatus\(item.pluginId, "degraded", "E_LAUNCHER_EXECUTE", String\(e\)\);' "plugin service marks execute failures as degraded"

printf '[INFO] Plugin reference recovery summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
