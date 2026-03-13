#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fixtures_dir="${script_dir}/../fixtures/plugins"
doctor_script="${script_dir}/plugin-doctor.sh"

if [[ ! -x "$doctor_script" ]]; then
  echo "[FAIL] plugin-doctor script not executable: ${doctor_script}" >&2
  exit 1
fi

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

valid_tmp="$(mktemp -d)"
trap 'rm -rf "$valid_tmp"' EXIT

for d in "$fixtures_dir"/valid-*; do
  cp -R "$d" "$valid_tmp/"
done

if "$doctor_script" "$valid_tmp" >/tmp/plugin_doctor_valid.out 2>/tmp/plugin_doctor_valid.err; then
  pass "plugin-doctor passes on valid fixtures"
else
  fail "plugin-doctor should pass on valid fixtures"
  sed -n '1,120p' /tmp/plugin_doctor_valid.err >&2
fi

if "$doctor_script" "$fixtures_dir" >/tmp/plugin_doctor_all.out 2>/tmp/plugin_doctor_all.err; then
  fail "plugin-doctor should fail on mixed fixtures"
else
  if rg -q 'E_MANIFEST_VALIDATION|E_DUPLICATE_PLUGIN_ID' /tmp/plugin_doctor_all.err; then
    pass "plugin-doctor reports expected failure codes on invalid fixtures"
  else
    fail "plugin-doctor failed, but expected error codes were not found"
    sed -n '1,120p' /tmp/plugin_doctor_all.err >&2
  fi
fi

if "$doctor_script" --json "$fixtures_dir" >/tmp/plugin_doctor_json.out 2>/tmp/plugin_doctor_json.err; then
  fail "plugin-doctor --json should fail on mixed fixtures"
else
  if jq -e '.schemaVersion == 1 and .summary.fail > 0 and (.entries | type == "array")' /tmp/plugin_doctor_json.out >/dev/null 2>&1; then
    pass "plugin-doctor --json returns machine-readable failure diagnostics"
  else
    fail "plugin-doctor --json output missing expected structure"
    sed -n '1,120p' /tmp/plugin_doctor_json.out >&2
  fi
fi

printf '[INFO] Plugin doctor smoke summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
