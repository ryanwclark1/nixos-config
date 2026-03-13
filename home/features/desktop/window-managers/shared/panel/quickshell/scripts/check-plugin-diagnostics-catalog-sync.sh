#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
runtime_catalog="${script_dir}/../config/plugins/runtime-catalog.json"
diagnostics_schema="${script_dir}/../config/plugins/diagnostics.schema.json"

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

if ! command -v jq >/dev/null 2>&1; then
  echo '[FAIL] jq is required for diagnostics catalog sync checks' >&2
  exit 1
fi

if [[ ! -f "$runtime_catalog" ]]; then
  echo "[FAIL] Missing runtime catalog: ${runtime_catalog}" >&2
  exit 1
fi

if [[ ! -f "$diagnostics_schema" ]]; then
  echo "[FAIL] Missing diagnostics schema: ${diagnostics_schema}" >&2
  exit 1
fi

catalog_states="$(jq -c '.states | keys | sort' "$runtime_catalog")"
schema_states="$(jq -c '.properties.uiExportJson.properties.plugins.items.properties.runtime.properties.state.enum // [] | sort' "$diagnostics_schema")"
if [[ "$catalog_states" == "$schema_states" ]]; then
  pass "diagnostics schema runtime.state enum matches runtime catalog states"
else
  fail "runtime.state enum is out of sync with runtime catalog states"
fi

catalog_codes="$(jq -c '([""] + (.errors | keys)) | sort' "$runtime_catalog")"
schema_codes="$(jq -c '.properties.uiExportJson.properties.plugins.items.properties.runtime.properties.code.enum // [] | sort' "$diagnostics_schema")"
if [[ "$catalog_codes" == "$schema_codes" ]]; then
  pass "diagnostics schema runtime.code enum matches runtime catalog errors (+ empty)"
else
  fail "runtime.code enum is out of sync with runtime catalog errors"
fi

catalog_state_severity="$(jq -c '.states | to_entries | map(.value.severity) | unique | sort' "$runtime_catalog")"
schema_state_severity="$(jq -c '.properties.uiExportJson.properties.plugins.items.properties.runtime.properties.stateSeverity.enum // [] | sort' "$diagnostics_schema")"
if [[ "$catalog_state_severity" == "$schema_state_severity" ]]; then
  pass "diagnostics schema stateSeverity enum matches runtime catalog state severities"
else
  fail "stateSeverity enum is out of sync with runtime catalog state severities"
fi

catalog_code_severity="$(jq -c '(["muted"] + (.errors | to_entries | map(.value.severity))) | unique | sort' "$runtime_catalog")"
schema_code_severity="$(jq -c '.properties.uiExportJson.properties.plugins.items.properties.runtime.properties.codeSeverity.enum // [] | sort' "$diagnostics_schema")"
if [[ "$catalog_code_severity" == "$schema_code_severity" ]]; then
  pass "diagnostics schema codeSeverity enum matches runtime catalog error severities (+ muted)"
else
  fail "codeSeverity enum is out of sync with runtime catalog error severities"
fi

printf '[INFO] Plugin diagnostics catalog sync summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
