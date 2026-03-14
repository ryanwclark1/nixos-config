#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
plugin_service="${script_dir}/../config/services/PluginService.qml"
plugin_runtime="${script_dir}/../config/services/PluginRuntime.qml"
runtime_catalog="${script_dir}/../config/plugins/runtime-catalog.json"

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
  local pattern="$1"
  local label="$2"
  if rg -q "$pattern" "$plugin_service" "$plugin_runtime"; then
    pass "$label"
  else
    fail "$label"
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  echo '[FAIL] jq is required for plugin runtime guard checks' >&2
  exit 1
fi

if [[ ! -f "$runtime_catalog" ]]; then
  echo "[FAIL] Missing runtime catalog: $runtime_catalog" >&2
  exit 1
fi
if [[ ! -f "$plugin_runtime" ]]; then
  echo "[FAIL] Missing plugin runtime: $plugin_runtime" >&2
  exit 1
fi

require_pattern 'function _setPluginStatus\(' 'plugin status setter exists'
require_pattern 'updatedAt:' 'plugin status transition timestamp is tracked'

# Lifecycle states that must remain representable in status updates.
while IFS= read -r state; do
  if rg -q "\"${state}\"" "$plugin_service" "$plugin_runtime"; then
    pass "lifecycle state '${state}' is used"
  else
    fail "lifecycle state '${state}' is missing"
  fi
done < <(jq -r '.states | keys[]' "$runtime_catalog")

# State envelope + migration API invariants.
require_pattern 'function _normalizeStateEnvelope\(' 'state envelope normalizer exists'
require_pattern 'function _readStateEnvelope\(' 'state envelope reader exists'
require_pattern 'function _writeStateEnvelope\(' 'state envelope writer exists'
require_pattern 'loadStateEnvelope: function\(' 'plugin API exposes loadStateEnvelope'
require_pattern 'saveStateEnvelope: function\(' 'plugin API exposes saveStateEnvelope'
require_pattern 'migrateState: function\(' 'plugin API exposes migrateState'

# Canonical error code guardrails.
while IFS= read -r code; do
  if rg -q "$code" "$plugin_service" "$plugin_runtime"; then
    pass "error code '${code}' is present"
  else
    fail "error code '${code}' is missing"
  fi
done < <(jq -r '.errors | keys[]' "$runtime_catalog")

printf '[INFO] Plugin runtime guard summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
