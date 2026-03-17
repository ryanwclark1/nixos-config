#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
fixtures_dir="${script_dir}/../fixtures/plugins"
doctor_script="${script_dir}/plugin-doctor.sh"
plugins_tab="${script_dir}/../src/menu/settings/tabs/PluginsTab.qml"
contracts_schema="${script_dir}/../src/plugins/diagnostics.schema.json"

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
  if rg -q "$pattern" "$plugins_tab"; then
    pass "$label"
  else
    fail "$label"
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  echo '[FAIL] jq is required for diagnostics contract checks' >&2
  exit 1
fi

if [[ ! -x "$doctor_script" ]]; then
  echo "[FAIL] Missing executable script: ${doctor_script}" >&2
  exit 1
fi

if [[ ! -f "$plugins_tab" ]]; then
  echo "[FAIL] Missing plugins tab file: ${plugins_tab}" >&2
  exit 1
fi

if [[ ! -f "$contracts_schema" ]]; then
  echo "[FAIL] Missing diagnostics schema: ${contracts_schema}" >&2
  exit 1
fi

if jq -e '.properties.doctorJson.properties.schemaVersion.const == 1 and .properties.uiExportJson.properties.schemaVersion.const == 1' "$contracts_schema" >/dev/null 2>&1; then
  pass "diagnostics schema exists with v1 contracts"
else
  fail "diagnostics schema contract missing expected schemaVersion constants"
fi

doctor_json_output="$(mktemp)"
doctor_json_error="$(mktemp)"
trap 'rm -f "$doctor_json_output" "$doctor_json_error"' EXIT

if "$doctor_script" --json "$fixtures_dir" >"$doctor_json_output" 2>"$doctor_json_error"; then
  fail "plugin-doctor --json should fail on mixed fixtures"
else
  if jq -e '
    .schemaVersion == 1
    and (.generatedAt | type == "string")
    and (.pluginsDir | type == "string")
    and (.summary | type == "object")
    and (.summary.pass | type == "number")
    and (.summary.fail | type == "number")
    and (.summary.warn | type == "number")
    and (.entries | type == "array")
    and ([.entries[] | (.status == "PASS" or .status == "FAIL" or .status == "WARN")
                     and (.name | type == "string")
                     and (.code | type == "string")
                     and (.message | type == "string")] | all)
  ' "$doctor_json_output" >/dev/null 2>&1; then
    pass "plugin-doctor --json output matches machine-readable contract"
  else
    fail "plugin-doctor --json output violates machine-readable contract"
    sed -n '1,120p' "$doctor_json_output" >&2
  fi
fi

require_pattern 'function pluginDiagnosticsPayload\(' 'plugins tab defines diagnostics payload builder'
require_pattern 'schemaVersion: 1' 'plugins diagnostics payload sets schemaVersion 1'
require_pattern 'generatedAt:' 'plugins diagnostics payload includes generatedAt'
require_pattern 'summary:' 'plugins diagnostics payload includes summary object'
require_pattern 'plugins:' 'plugins diagnostics payload includes plugins array field'
require_pattern 'manifestErrors:' 'plugins diagnostics payload includes manifestErrors field'
require_pattern 'stateLabel:' 'plugins diagnostics payload includes runtime state label'
require_pattern 'stateSeverity:' 'plugins diagnostics payload includes runtime state severity'
require_pattern 'codeLabel:' 'plugins diagnostics payload includes runtime code label'
require_pattern 'codeSeverity:' 'plugins diagnostics payload includes runtime code severity'
require_pattern 'function savePluginDiagnostics\(' 'plugins tab defines save diagnostics action'
require_pattern 'plugin-diagnostics-' 'save diagnostics filename prefix is stable'

printf '[INFO] Plugin diagnostics contract summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
