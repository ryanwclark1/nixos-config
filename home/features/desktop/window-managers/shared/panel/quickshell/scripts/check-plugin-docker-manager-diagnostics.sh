#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
docker_dir="${script_dir}/../examples/plugins/docker-manager"
active_fixture="${docker_dir}/expected-diagnostics-active.json"
degraded_fixture="${docker_dir}/expected-diagnostics-degraded.json"
schema_file="${script_dir}/../config/plugins/diagnostics.schema.json"
schema_validator="${script_dir}/validate-json-schema.js"
plugins_tab="${script_dir}/../config/menu/settings/tabs/PluginsTab.qml"

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
  echo '[FAIL] jq is required for docker-manager diagnostics checks' >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo '[FAIL] node is required for docker-manager diagnostics checks' >&2
  exit 1
fi

for required in "$active_fixture" "$degraded_fixture" "$schema_file" "$schema_validator" "$plugins_tab"; do
  if [[ ! -f "$required" ]]; then
    echo "[FAIL] Missing docker-manager diagnostics file: ${required}" >&2
    exit 1
  fi
done

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
ui_schema="${tmp_dir}/ui.schema.json"
jq '.properties.uiExportJson' "$schema_file" >"$ui_schema"

if node "$schema_validator" "$ui_schema" "$active_fixture" >/dev/null 2>&1; then
  pass "docker-manager active diagnostics fixture validates against the UI diagnostics schema"
else
  fail "docker-manager active diagnostics fixture failed UI diagnostics schema validation"
fi

if node "$schema_validator" "$ui_schema" "$degraded_fixture" >/dev/null 2>&1; then
  pass "docker-manager degraded diagnostics fixture validates against the UI diagnostics schema"
else
  fail "docker-manager degraded diagnostics fixture failed UI diagnostics schema validation"
fi

if jq -e '
  .summary.statuses.active == 1
  and .plugins[0].id == "docker.manager"
  and .plugins[0].runtime.state == "active"
  and .plugins[0].runtime.stateLabel == "Active"
  and .plugins[0].runtime.code == ""
  and .plugins[0].runtime.codeSeverity == "muted"
' "$active_fixture" >/dev/null 2>&1; then
  pass "docker-manager active diagnostics fixture matches the expected healthy export"
else
  fail "docker-manager active diagnostics fixture drifted from the expected healthy export"
fi

if jq -e '
  .summary.statuses.degraded == 1
  and .plugins[0].id == "docker.manager"
  and .plugins[0].runtime.state == "degraded"
  and .plugins[0].runtime.stateLabel == "Degraded"
  and .plugins[0].runtime.code == "E_DOCKER_RUNTIME_UNAVAILABLE"
  and .plugins[0].runtime.codeLabel == "Docker Runtime Unavailable"
  and .plugins[0].runtime.codeSeverity == "warn"
  and .plugins[0].runtime.message == "Runtime binary not found"
' "$degraded_fixture" >/dev/null 2>&1; then
  pass "docker-manager degraded diagnostics fixture matches the expected missing-runtime export"
else
  fail "docker-manager degraded diagnostics fixture drifted from the expected missing-runtime export"
fi

require_pattern "$plugins_tab" 'function pluginDiagnosticsPayload\(' "plugins tab still exposes the diagnostics payload builder"
require_pattern "$plugins_tab" 'stateLabel: PluginRuntimeCatalog.stateLabel\(state\)' "plugins tab exports runtime state labels from the runtime catalog"
require_pattern "$plugins_tab" 'codeLabel: code !== "" \? PluginRuntimeCatalog.errorLabel\(code\) : ""' "plugins tab exports runtime error labels from the runtime catalog"
require_pattern "$plugins_tab" 'codeSeverity: code !== "" \? PluginRuntimeCatalog.errorSeverity\(code\) : "muted"' "plugins tab exports runtime error severities from the runtime catalog"

printf '[INFO] Plugin docker diagnostics summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
