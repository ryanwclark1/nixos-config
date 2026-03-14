#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
local_runner="${script_dir}/plugin-local.sh"
reference_dir_name="reference-local-toolkit"

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

tmp_plugins="$(mktemp -d)"
trap 'rm -rf "$tmp_plugins"' EXIT

reference_path="${tmp_plugins}/${reference_dir_name}"

if "$local_runner" install-reference "$tmp_plugins" >/tmp/plugin_reference_install.out 2>/tmp/plugin_reference_install.err; then
  pass "plugin-local install-reference links the reference plugin into the target directory"
else
  fail "plugin-local install-reference should succeed on an empty target directory"
  sed -n '1,120p' /tmp/plugin_reference_install.err >&2
fi

if [[ -L "$reference_path" && -f "$reference_path/manifest.json" ]]; then
  pass "reference plugin link points to a plugin manifest"
else
  fail "reference plugin manifest is not present after install-reference"
fi

if "$local_runner" smoke-reference "$tmp_plugins" >/tmp/plugin_reference_smoke.out 2>/tmp/plugin_reference_smoke.err; then
  pass "plugin-local smoke-reference validates the installed reference plugin"
else
  fail "plugin-local smoke-reference should pass for the installed reference plugin"
  sed -n '1,120p' /tmp/plugin_reference_smoke.err >&2
fi

if "$local_runner" remove-reference "$tmp_plugins" >/tmp/plugin_reference_remove.out 2>/tmp/plugin_reference_remove.err; then
  pass "plugin-local remove-reference removes the linked reference plugin"
else
  fail "plugin-local remove-reference should remove the linked reference plugin"
  sed -n '1,120p' /tmp/plugin_reference_remove.err >&2
fi

if [[ ! -e "$reference_path" ]]; then
  pass "reference plugin path is absent after remove-reference"
else
  fail "reference plugin path still exists after remove-reference"
fi

printf '[INFO] Plugin reference local summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
