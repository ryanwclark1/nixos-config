#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
fixtures_dir="${script_dir}/../fixtures"

extract_active_jq='(if type == "array" then . else (.workspaces // []) end)[] | select(.is_active == true or .active == true or .is_focused == true or .focused == true) | (.name // .idx // .id // .index // empty)'

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

check_fixture() {
  local file="$1"
  local active

  if ! jq -e '.' "$file" >/dev/null 2>&1; then
    fail "Invalid JSON: ${file}"
    return
  fi
  pass "Valid JSON: ${file}"

  active="$(jq -r "$extract_active_jq" "$file" | head -n1 || true)"
  if [[ -n "$active" ]]; then
    pass "Active workspace extracted from $(basename "$file"): ${active}"
  else
    fail "No active workspace extracted from $(basename "$file")"
  fi
}

main() {
  if ! command -v jq >/dev/null 2>&1; then
    echo '[FAIL] jq is required for fixture checks' >&2
    exit 1
  fi

  check_fixture "${fixtures_dir}/niri-workspaces-array.json"
  check_fixture "${fixtures_dir}/niri-workspaces-object.json"

  printf '[INFO] Fixture summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
  (( fail_count == 0 ))
}

main "$@"
