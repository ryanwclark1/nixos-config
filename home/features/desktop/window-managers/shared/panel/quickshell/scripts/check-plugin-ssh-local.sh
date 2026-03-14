#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
plugin_dir="${script_dir}/../config/plugins/ssh-monitor"
doctor_script="${script_dir}/plugin-doctor.sh"
plugin_id="quickshell.ssh.monitor"

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
  echo '[FAIL] jq is required for ssh plugin local checks' >&2
  exit 1
fi

if [[ ! -x "$doctor_script" ]]; then
  echo "[FAIL] plugin-doctor script not executable: ${doctor_script}" >&2
  exit 1
fi

if [[ ! -d "$plugin_dir" ]]; then
  echo "[FAIL] Missing ssh plugin directory: ${plugin_dir}" >&2
  exit 1
fi

tmp_plugins="$(mktemp -d)"
tmp_json="$(mktemp)"
trap 'rm -rf "$tmp_plugins" "$tmp_json"' EXIT

cp -R "$plugin_dir" "${tmp_plugins}/ssh-monitor"

if "$doctor_script" --json "$tmp_plugins" >"$tmp_json" 2>/tmp/plugin_ssh_local.err; then
  if jq -e --arg id "$plugin_id" '
    .summary.fail == 0
    and .summary.pass == 1
    and ([.entries[] | select(.status == "PASS" and .name == "ssh-monitor")] | length) == 1
    and .pluginsDir != ""
  ' "$tmp_json" >/dev/null 2>&1; then
    pass "plugin-doctor validates the shipped ssh plugin directory in isolation"
  else
    fail "plugin-doctor json output for the shipped ssh plugin is missing the expected success payload"
    sed -n '1,120p' "$tmp_json" >&2
  fi
else
  fail "plugin-doctor should pass for the shipped ssh plugin directory"
  sed -n '1,120p' /tmp/plugin_ssh_local.err >&2
fi

if jq -e --arg id "$plugin_id" '.id == $id and .entryPoints.barWidget == "BarWidget.qml" and .entryPoints.launcherProvider == "LauncherProvider.qml" and .entryPoints.settings == "Settings.qml"' "${plugin_dir}/manifest.json" >/dev/null 2>&1; then
  pass "ssh plugin manifest keeps the expected shipped entry points"
else
  fail "ssh plugin manifest drifted from the expected shipped entry points"
fi

printf '[INFO] Plugin ssh local summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
