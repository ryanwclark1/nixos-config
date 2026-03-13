#!/usr/bin/env bash
set -euo pipefail

output_mode="text"
if [[ "${1:-}" == "--json" ]]; then
  output_mode="json"
  shift
fi

plugins_dir="${1:-${HOME}/.config/quickshell/plugins}"

if ! command -v jq >/dev/null 2>&1; then
  echo '[FAIL] jq is required for plugin doctor' >&2
  exit 1
fi

if [[ ! -d "$plugins_dir" ]]; then
  echo "[FAIL] Plugin directory not found: ${plugins_dir}" >&2
  exit 1
fi

entry_valid() {
  local value="$1"
  [[ -n "$value" ]] || return 1
  [[ "$value" == *.qml ]] || return 1
  [[ "$value" != *".."* ]] || return 1
  return 0
}

validate_one() {
  local dir="$1"
  local manifest="$dir/manifest.json"
  local required=(id name description author version type permissions entryPoints)
  local key

  [[ -f "$manifest" ]] || { echo "WARN|$(basename "$dir")|missing manifest.json"; return; }

  if ! jq -e . "$manifest" >/dev/null 2>&1; then
    echo "FAIL|$(basename "$dir")|E_JSON_PARSE|invalid json"
    return
  fi

  for key in "${required[@]}"; do
    if ! jq -e --arg k "$key" 'has($k)' "$manifest" >/dev/null; then
      echo "FAIL|$(basename "$dir")|E_MANIFEST_VALIDATION|missing required field: ${key}"
      return
    fi
  done

  local id type
  id="$(jq -r '.id // ""' "$manifest")"
  type="$(jq -r '.type // ""' "$manifest")"

  if [[ ! "$id" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
    echo "FAIL|$(basename "$dir")|E_MANIFEST_VALIDATION|id must be filesystem-safe"
    return
  fi

  case "$type" in
    bar-widget|desktop-widget|launcher-provider|daemon|multi) ;;
    *) echo "FAIL|$(basename "$dir")|E_MANIFEST_VALIDATION|invalid type: ${type}"; return ;;
  esac

  if ! jq -e '.entryPoints | type == "object"' "$manifest" >/dev/null; then
    echo "FAIL|$(basename "$dir")|E_MANIFEST_VALIDATION|entryPoints must be an object"
    return
  fi
  if ! jq -e '.permissions | type == "array"' "$manifest" >/dev/null; then
    echo "FAIL|$(basename "$dir")|E_MANIFEST_VALIDATION|permissions must be an array"
    return
  fi

  local perm
  while IFS= read -r perm; do
    case "$perm" in
      settings_read|settings_write|state_read|state_write|process) ;;
      *) echo "FAIL|$(basename "$dir")|E_MANIFEST_VALIDATION|invalid permission: ${perm}"; return ;;
    esac
  done < <(jq -r '.permissions[]? | tostring' "$manifest")

  local ep_bar ep_desktop ep_launcher ep_daemon ep_settings
  ep_bar="$(jq -r '.entryPoints.barWidget // ""' "$manifest")"
  ep_desktop="$(jq -r '.entryPoints.desktopWidget // ""' "$manifest")"
  ep_launcher="$(jq -r '.entryPoints.launcherProvider // ""' "$manifest")"
  ep_daemon="$(jq -r '.entryPoints.daemon // ""' "$manifest")"
  ep_settings="$(jq -r '.entryPoints.settings // ""' "$manifest")"

  if jq -e '.entryPoints | has("settings")' "$manifest" >/dev/null && ! entry_valid "$ep_settings"; then
    echo "FAIL|$(basename "$dir")|E_MANIFEST_VALIDATION|entryPoints.settings must be a .qml path"
    return
  fi

  if [[ "$type" == "bar-widget" ]] && ! entry_valid "$ep_bar"; then
    echo "FAIL|$(basename "$dir")|E_MANIFEST_VALIDATION|bar-widget type requires entryPoints.barWidget"
    return
  fi
  if [[ "$type" == "desktop-widget" ]] && ! entry_valid "$ep_desktop"; then
    echo "FAIL|$(basename "$dir")|E_MANIFEST_VALIDATION|desktop-widget type requires entryPoints.desktopWidget"
    return
  fi
  if [[ "$type" == "launcher-provider" ]] && ! entry_valid "$ep_launcher"; then
    echo "FAIL|$(basename "$dir")|E_MANIFEST_VALIDATION|launcher-provider type requires entryPoints.launcherProvider"
    return
  fi
  if [[ "$type" == "daemon" ]] && ! entry_valid "$ep_daemon"; then
    echo "FAIL|$(basename "$dir")|E_MANIFEST_VALIDATION|daemon type requires entryPoints.daemon"
    return
  fi
  if [[ "$type" == "multi" ]] && ! entry_valid "$ep_bar" && ! entry_valid "$ep_desktop" && ! entry_valid "$ep_launcher" && ! entry_valid "$ep_daemon"; then
    echo "FAIL|$(basename "$dir")|E_MANIFEST_VALIDATION|multi type requires at least one runtime entry point"
    return
  fi

  local rel
  for rel in "$ep_bar" "$ep_desktop" "$ep_launcher" "$ep_daemon" "$ep_settings"; do
    [[ -n "$rel" ]] || continue
    if [[ ! -f "$dir/$rel" ]]; then
      echo "FAIL|$(basename "$dir")|E_ENTRYPOINT_MISSING|missing file: ${rel}"
      return
    fi
  done

  echo "PASS|$(basename "$dir")|OK|manifest and entry points valid"
}

pass_count=0
fail_count=0
warn_count=0

declare -A id_counts=()
declare -A id_cases=()

declare -a reports=()
declare -a report_objects=()
while IFS= read -r dir; do
  report="$(validate_one "$dir")"
  reports+=("$report")
  IFS='|' read -r status name code msg <<<"$report"
  if [[ "$status" == "PASS" ]]; then
    id="$(jq -r '.id // ""' "$dir/manifest.json" 2>/dev/null || true)"
    if [[ -n "$id" ]]; then
      id_counts["$id"]=$(( ${id_counts["$id"]:-0} + 1 ))
      if [[ -n "${id_cases[$id]:-}" ]]; then
        id_cases["$id"]="${id_cases[$id]} ${name}"
      else
        id_cases["$id"]="$name"
      fi
    fi
  fi
done < <(find "$plugins_dir" -mindepth 1 -maxdepth 1 -type d | sort)

for id in "${!id_counts[@]}"; do
  if (( ${id_counts[$id]} > 1 )); then
    for case_name in ${id_cases[$id]}; do
      reports+=("FAIL|${case_name}|E_DUPLICATE_PLUGIN_ID|duplicate id: ${id}")
    done
  fi
done

for report in "${reports[@]}"; do
  IFS='|' read -r status name code msg <<<"$report"
  report_objects+=("$(jq -nc \
    --arg status "$status" \
    --arg name "$name" \
    --arg code "$code" \
    --arg message "$msg" \
    '{status:$status,name:$name,code:$code,message:$message}')")
  case "$status" in
    PASS)
      if [[ "$output_mode" == "text" ]]; then
        printf '[PASS] %s: %s\n' "$name" "$msg"
      fi
      pass_count=$((pass_count + 1))
      ;;
    FAIL)
      if [[ "$output_mode" == "text" ]]; then
        printf '[FAIL] %s: [%s] %s\n' "$name" "$code" "$msg" >&2
      fi
      fail_count=$((fail_count + 1))
      ;;
    WARN)
      if [[ "$output_mode" == "text" ]]; then
        printf '[WARN] %s: %s\n' "$name" "$msg"
      fi
      warn_count=$((warn_count + 1))
      ;;
  esac
done

if [[ "$output_mode" == "text" ]]; then
  printf '[INFO] Plugin doctor summary for %s: %d pass, %d fail, %d warn\n' "$plugins_dir" "$pass_count" "$fail_count" "$warn_count"
else
  entries_json="[]"
  if (( ${#report_objects[@]} > 0 )); then
    entries_json="$(printf '%s\n' "${report_objects[@]}" | jq -s '.')"
  fi
  jq -n \
    --arg pluginsDir "$plugins_dir" \
    --arg generatedAt "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --argjson pass "$pass_count" \
    --argjson fail "$fail_count" \
    --argjson warn "$warn_count" \
    --argjson entries "$entries_json" \
    '{
      schemaVersion: 1,
      generatedAt: $generatedAt,
      pluginsDir: $pluginsDir,
      summary: {
        pass: $pass,
        fail: $fail,
        warn: $warn
      },
      entries: $entries
    }'
fi

(( fail_count == 0 ))
