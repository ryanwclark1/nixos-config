#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
runtime_catalog="${script_dir}/../config/plugins/runtime-catalog.json"
diagnostics_schema="${script_dir}/../config/plugins/diagnostics.schema.json"

mode="${1:---write}"
if [[ "$mode" != "--write" && "$mode" != "--check" ]]; then
  echo "Usage: $0 [--write|--check]" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo '[FAIL] jq is required for diagnostics schema sync' >&2
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

state_enum="$(jq -c '.states | keys | sort' "$runtime_catalog")"
code_enum="$(jq -c '([""] + (.errors | keys)) | sort' "$runtime_catalog")"
state_severity_enum="$(jq -c '.states | to_entries | map(.value.severity) | unique | sort' "$runtime_catalog")"
code_severity_enum="$(jq -c '(["muted"] + (.errors | to_entries | map(.value.severity))) | unique | sort' "$runtime_catalog")"

updated_schema="$(
  jq \
    --argjson stateEnum "$state_enum" \
    --argjson codeEnum "$code_enum" \
    --argjson stateSeverityEnum "$state_severity_enum" \
    --argjson codeSeverityEnum "$code_severity_enum" \
    '
      .properties.uiExportJson.properties.plugins.items.properties.runtime.properties.state.enum = $stateEnum
      | .properties.uiExportJson.properties.plugins.items.properties.runtime.properties.code.enum = $codeEnum
      | .properties.uiExportJson.properties.plugins.items.properties.runtime.properties.stateSeverity.enum = $stateSeverityEnum
      | .properties.uiExportJson.properties.plugins.items.properties.runtime.properties.codeSeverity.enum = $codeSeverityEnum
    ' \
    "$diagnostics_schema"
)"

if [[ "$mode" == "--check" ]]; then
  current_norm="$(jq -S . "$diagnostics_schema")"
  updated_norm="$(printf '%s\n' "$updated_schema" | jq -S .)"
  if [[ "$current_norm" == "$updated_norm" ]]; then
    echo '[PASS] diagnostics schema enums are synchronized with runtime catalog'
  else
    echo '[FAIL] diagnostics schema enums are out of sync (run sync-plugin-diagnostics-schema.sh --write)' >&2
    exit 1
  fi
  exit 0
fi

printf '%s\n' "$updated_schema" > "$diagnostics_schema"
echo "[INFO] Updated diagnostics schema enums from runtime catalog: ${diagnostics_schema}"
