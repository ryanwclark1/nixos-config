#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
fixtures_dir="${script_dir}/../fixtures/plugins"

if ! command -v jq >/dev/null 2>&1; then
  echo '[FAIL] jq is required for plugin conformance checks' >&2
  exit 1
fi

declare -A manifest_path_by_case=()
declare -A manifest_id_by_case=()
declare -A expected_valid_by_case=()
declare -A actual_valid_by_case=()
declare -A actual_code_by_case=()
declare -A actual_msg_by_case=()
declare -A duplicate_count_by_id=()

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

entry_valid() {
  local value="$1"
  [[ -n "$value" ]] || return 1
  [[ "$value" == *.qml ]] || return 1
  [[ "$value" != *".."* ]] || return 1
  return 0
}

validate_manifest() {
  local file="$1"
  local required=(id name description author version type permissions entryPoints)
  local key

  if ! jq -e . "$file" >/dev/null 2>&1; then
    echo "E_JSON_PARSE|invalid json"
    return
  fi

  for key in "${required[@]}"; do
    if ! jq -e --arg k "$key" 'has($k)' "$file" >/dev/null; then
      echo "E_MANIFEST_VALIDATION|missing required field: ${key}"
      return
    fi
  done

  local plugin_id type_name
  plugin_id="$(jq -r '.id // ""' "$file")"
  type_name="$(jq -r '.type // ""' "$file")"

  if [[ ! "$plugin_id" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
    echo "E_MANIFEST_VALIDATION|id must be filesystem-safe"
    return
  fi

  case "$type_name" in
    bar-widget|desktop-widget|launcher-provider|control-center-widget|daemon|multi) ;;
    *) echo "E_MANIFEST_VALIDATION|invalid type: ${type_name}"; return ;;
  esac

  if ! jq -e '.entryPoints | type == "object"' "$file" >/dev/null; then
    echo "E_MANIFEST_VALIDATION|entryPoints must be an object"
    return
  fi

  if ! jq -e '.permissions | type == "array"' "$file" >/dev/null; then
    echo "E_MANIFEST_VALIDATION|permissions must be an array"
    return
  fi

  local perm
  while IFS= read -r perm; do
    [[ -n "$perm" ]] || { echo "E_MANIFEST_VALIDATION|invalid permission: ${perm}"; return; }
    case "$perm" in
      settings_read|settings_write|state_read|state_write|process) ;;
      *) echo "E_MANIFEST_VALIDATION|invalid permission: ${perm}"; return ;;
    esac
  done < <(jq -r '.permissions[]? | tostring' "$file")

  local ep_bar ep_desktop ep_launcher ep_control_center ep_control_center_detail ep_daemon ep_settings
  ep_bar="$(jq -r '.entryPoints.barWidget // ""' "$file")"
  ep_desktop="$(jq -r '.entryPoints.desktopWidget // ""' "$file")"
  ep_launcher="$(jq -r '.entryPoints.launcherProvider // ""' "$file")"
  ep_control_center="$(jq -r '.entryPoints.controlCenterWidget // ""' "$file")"
  ep_control_center_detail="$(jq -r '.entryPoints.controlCenterDetail // ""' "$file")"
  ep_daemon="$(jq -r '.entryPoints.daemon // ""' "$file")"
  ep_settings="$(jq -r '.entryPoints.settings // ""' "$file")"

  if jq -e '.entryPoints | has("settings")' "$file" >/dev/null; then
    entry_valid "$ep_settings" || { echo "E_MANIFEST_VALIDATION|entryPoints.settings must be a .qml path"; return; }
  fi
  if jq -e '.entryPoints | has("controlCenterDetail")' "$file" >/dev/null; then
    entry_valid "$ep_control_center_detail" || { echo "E_MANIFEST_VALIDATION|entryPoints.controlCenterDetail must be a .qml path"; return; }
  fi

  if [[ "$type_name" == "bar-widget" ]] && ! entry_valid "$ep_bar"; then
    echo "E_MANIFEST_VALIDATION|bar-widget type requires entryPoints.barWidget"
    return
  fi
  if [[ "$type_name" == "desktop-widget" ]] && ! entry_valid "$ep_desktop"; then
    echo "E_MANIFEST_VALIDATION|desktop-widget type requires entryPoints.desktopWidget"
    return
  fi
  if [[ "$type_name" == "launcher-provider" ]] && ! entry_valid "$ep_launcher"; then
    echo "E_MANIFEST_VALIDATION|launcher-provider type requires entryPoints.launcherProvider"
    return
  fi
  if [[ "$type_name" == "control-center-widget" ]] && ! entry_valid "$ep_control_center"; then
    echo "E_MANIFEST_VALIDATION|control-center-widget type requires entryPoints.controlCenterWidget"
    return
  fi
  if [[ "$type_name" == "daemon" ]] && ! entry_valid "$ep_daemon"; then
    echo "E_MANIFEST_VALIDATION|daemon type requires entryPoints.daemon"
    return
  fi
  if [[ "$type_name" == "multi" ]]; then
    if ! entry_valid "$ep_bar" && ! entry_valid "$ep_desktop" && ! entry_valid "$ep_launcher" && ! entry_valid "$ep_control_center" && ! entry_valid "$ep_daemon"; then
      echo "E_MANIFEST_VALIDATION|multi type requires at least one runtime entry point"
      return
    fi
  fi

  echo "OK|valid"
}

while IFS= read -r manifest; do
  case_dir="$(basename "$(dirname "$manifest")")"
  manifest_path_by_case["$case_dir"]="$manifest"

  if [[ "$case_dir" == valid-* ]]; then
    expected_valid_by_case["$case_dir"]=1
  elif [[ "$case_dir" == invalid-* ]]; then
    expected_valid_by_case["$case_dir"]=0
  else
    fail "Unknown fixture naming convention: ${case_dir}"
    continue
  fi

  result="$(validate_manifest "$manifest")"
  code="${result%%|*}"
  msg="${result#*|}"

  if [[ "$code" == "OK" ]]; then
    actual_valid_by_case["$case_dir"]=1
    actual_code_by_case["$case_dir"]=""
    actual_msg_by_case["$case_dir"]=""
  else
    actual_valid_by_case["$case_dir"]=0
    actual_code_by_case["$case_dir"]="$code"
    actual_msg_by_case["$case_dir"]="$msg"
  fi

  plugin_id="$(jq -r '.id // ""' "$manifest" 2>/dev/null || true)"
  manifest_id_by_case["$case_dir"]="$plugin_id"
  if [[ -n "$plugin_id" ]]; then
    duplicate_count_by_id["$plugin_id"]=$(( ${duplicate_count_by_id["$plugin_id"]:-0} + 1 ))
  fi
done < <(find "$fixtures_dir" -mindepth 2 -maxdepth 2 -type f -name 'manifest.json' | sort)

# Apply duplicate id failure rule after single-manifest validation.
for case_dir in "${!manifest_id_by_case[@]}"; do
  plugin_id="${manifest_id_by_case[$case_dir]}"
  if [[ -n "$plugin_id" ]] && (( ${duplicate_count_by_id["$plugin_id"]:-0} > 1 )); then
    actual_valid_by_case["$case_dir"]=0
    actual_code_by_case["$case_dir"]="E_DUPLICATE_PLUGIN_ID"
    actual_msg_by_case["$case_dir"]="duplicate plugin id"
  fi
done

for case_dir in "${!manifest_path_by_case[@]}"; do
  expected="${expected_valid_by_case[$case_dir]:-}"
  actual="${actual_valid_by_case[$case_dir]:-0}"
  if [[ "$expected" == "$actual" ]]; then
    if [[ "$actual" == "1" ]]; then
      pass "${case_dir} valid as expected"
    else
      pass "${case_dir} invalid as expected (${actual_code_by_case[$case_dir]}: ${actual_msg_by_case[$case_dir]})"
    fi
  else
    fail "${case_dir} expected valid=${expected}, got valid=${actual} (${actual_code_by_case[$case_dir]}: ${actual_msg_by_case[$case_dir]})"
  fi
done

printf '[INFO] Plugin conformance summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
