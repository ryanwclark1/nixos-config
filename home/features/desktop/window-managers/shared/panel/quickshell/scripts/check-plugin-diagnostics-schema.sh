#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
fixtures_dir="${script_dir}/../fixtures/plugins"
doctor_script="${script_dir}/plugin-doctor.sh"
schema_file="${script_dir}/../src/plugins/diagnostics.schema.json"
schema_validator="${script_dir}/validate-json-schema.js"

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
  echo '[FAIL] jq is required for diagnostics schema checks' >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo '[FAIL] node is required for diagnostics schema checks' >&2
  exit 1
fi

if [[ ! -x "$doctor_script" ]]; then
  echo "[FAIL] Missing executable plugin doctor script: ${doctor_script}" >&2
  exit 1
fi

if [[ ! -f "$schema_file" ]]; then
  echo "[FAIL] Missing diagnostics schema file: ${schema_file}" >&2
  exit 1
fi

if [[ ! -f "$schema_validator" ]]; then
  echo "[FAIL] Missing schema validator script: ${schema_validator}" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

doctor_schema="${tmp_dir}/doctor.schema.json"
ui_schema="${tmp_dir}/ui.schema.json"
doctor_json="${tmp_dir}/doctor.valid.json"
doctor_invalid_json="${tmp_dir}/doctor.invalid.json"
ui_json="${tmp_dir}/ui.valid.json"
ui_invalid_json="${tmp_dir}/ui.invalid.json"
ui_plugin_bad_entrypoint_json="${tmp_dir}/ui.bad-entrypoint.json"
doctor_err="${tmp_dir}/doctor.err"

jq '.properties.doctorJson' "$schema_file" >"$doctor_schema"
jq '.properties.uiExportJson' "$schema_file" >"$ui_schema"

if "$doctor_script" --json "$fixtures_dir" >"$doctor_json" 2>"$doctor_err"; then
  fail "plugin-doctor --json should fail on mixed fixtures"
else
  pass "plugin-doctor --json produced diagnostics payload for schema validation"
fi

jq 'del(.summary.fail)' "$doctor_json" >"$doctor_invalid_json"

jq -n '{
  schemaVersion: 1,
  generatedAt: "2026-01-01T00:00:00Z",
  summary: {
    installed: 1,
    enabled: 1,
    invalidManifests: 0,
    statuses: {
      active: 1,
      enabled: 1,
      degraded: 0,
      failed: 0,
      disabled: 0,
      validated: 0,
      discovered: 0,
      unknown: 0
    }
  },
  plugins: [
    {
      id: "samplePlugin",
      name: "Sample Plugin",
      version: "1.0.0",
      type: "bar-widget",
      enabled: true,
      author: "tester",
      permissions: ["settings_read", "state_read"],
      entryPoints: {
        barWidget: "Widget.qml",
        settings: "Settings.qml"
      },
      runtime: {
        state: "active",
        stateLabel: "Active",
        stateSeverity: "ok",
        code: "",
        codeLabel: "",
        codeSeverity: "muted",
        message: "",
        updatedAt: "2026-01-01T00:00:00Z"
      }
    }
  ],
  manifestErrors: []
}' >"$ui_json"

jq 'del(.manifestErrors)' "$ui_json" >"$ui_invalid_json"
jq '.plugins[0].entryPoints.unknown = "Nope.qml"' "$ui_json" >"$ui_plugin_bad_entrypoint_json"

if node "$schema_validator" "$doctor_schema" "$doctor_json" >/dev/null 2>&1; then
  pass "doctor diagnostics payload validates against schema"
else
  fail "doctor diagnostics payload failed schema validation"
fi

if node "$schema_validator" "$doctor_schema" "$doctor_invalid_json" >/dev/null 2>&1; then
  fail "invalid doctor diagnostics sample should fail schema validation"
else
  pass "invalid doctor diagnostics sample is rejected by schema"
fi

if node "$schema_validator" "$ui_schema" "$ui_json" >/dev/null 2>&1; then
  pass "ui diagnostics payload sample validates against schema"
else
  fail "ui diagnostics payload sample failed schema validation"
fi

if node "$schema_validator" "$ui_schema" "$ui_invalid_json" >/dev/null 2>&1; then
  fail "invalid ui diagnostics sample should fail schema validation"
else
  pass "invalid ui diagnostics sample is rejected by schema"
fi

if node "$schema_validator" "$ui_schema" "$ui_plugin_bad_entrypoint_json" >/dev/null 2>&1; then
  fail "ui diagnostics sample with unknown entryPoints key should fail schema validation"
else
  pass "ui diagnostics sample rejects unknown entryPoints keys"
fi

printf '[INFO] Plugin diagnostics schema summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
