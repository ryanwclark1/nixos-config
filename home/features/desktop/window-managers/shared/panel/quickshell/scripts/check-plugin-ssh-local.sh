#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
plugin_dir="${script_dir}/../config/plugins/ssh-monitor"
doctor_script="${script_dir}/plugin-doctor.sh"
local_runner="${script_dir}/plugin-local.sh"
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
tmp_status_out="$(mktemp)"
tmp_status_err="$(mktemp)"
tmp_status_quiet_out="$(mktemp)"
tmp_status_quiet_err="$(mktemp)"
tmp_files_out="$(mktemp)"
tmp_files_err="$(mktemp)"
tmp_flow_out="$(mktemp)"
tmp_flow_err="$(mktemp)"
tmp_guards_out="$(mktemp)"
tmp_guards_err="$(mktemp)"
tmp_all_out="$(mktemp)"
tmp_all_err="$(mktemp)"
tmp_help_out="$(mktemp)"
tmp_help_err="$(mktemp)"
trap 'rm -rf "$tmp_plugins" "$tmp_json" "$tmp_status_out" "$tmp_status_err" "$tmp_status_quiet_out" "$tmp_status_quiet_err" "$tmp_files_out" "$tmp_files_err" "$tmp_flow_out" "$tmp_flow_err" "$tmp_guards_out" "$tmp_guards_err" "$tmp_all_out" "$tmp_all_err" "$tmp_help_out" "$tmp_help_err"' EXIT

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

if "$local_runner" ssh-status --check >"$tmp_status_out" 2>"$tmp_status_err"; then
  if rg -q 'SSH status check passed' "$tmp_status_out"; then
    pass "plugin-local ssh-status --check validates the shipped ssh plugin workflow prerequisites"
  else
    fail "plugin-local ssh-status --check did not report the expected success line"
    sed -n '1,120p' "$tmp_status_out" >&2
  fi
else
  fail "plugin-local ssh-status --check should succeed for the shipped ssh plugin"
  sed -n '1,120p' "$tmp_status_err" >&2
fi

if "$local_runner" ssh-status --check --quiet >"$tmp_status_quiet_out" 2>"$tmp_status_quiet_err"; then
  if rg -q '^\[INFO\] SSH status:' "$tmp_status_quiet_out" \
    && ! rg -q '^First-Party SSH Plugin Status$' "$tmp_status_quiet_out" \
    && rg -q 'SSH status check passed' "$tmp_status_quiet_out"; then
    pass "plugin-local ssh-status --check --quiet emits the compact ssh status line"
  else
    fail "plugin-local ssh-status --check --quiet output drifted from the expected compact status form"
    sed -n '1,120p' "$tmp_status_quiet_out" >&2
  fi
else
  fail "plugin-local ssh-status --check --quiet should succeed for the shipped ssh plugin"
  sed -n '1,120p' "$tmp_status_quiet_err" >&2
fi

if "$local_runner" ssh-files >"$tmp_files_out" 2>"$tmp_files_err"; then
  if rg -q '^plugin_id=quickshell\.ssh\.monitor$' "$tmp_files_out" \
    && rg -q 'guard_runtime_smoke=.*/check-plugin-ssh-runtime-smoke\.sh$' "$tmp_files_out"; then
    pass "plugin-local ssh-files prints the canonical ssh plugin file and guard paths"
  else
    fail "plugin-local ssh-files output drifted from the expected ssh plugin file summary"
    sed -n '1,120p' "$tmp_files_out" >&2
  fi
else
  fail "plugin-local ssh-files should succeed"
  sed -n '1,120p' "$tmp_files_err" >&2
fi

if "$local_runner" ssh-flow >"$tmp_flow_out" 2>"$tmp_flow_err"; then
  if rg -q '^First-Party SSH Plugin Manual Flow$' "$tmp_flow_out" \
    && rg -q 'launcher mode with `!ssh`' "$tmp_flow_out"; then
    pass "plugin-local ssh-flow documents the expected manual ssh plugin validation sequence"
  else
    fail "plugin-local ssh-flow output drifted from the expected ssh plugin manual flow"
    sed -n '1,120p' "$tmp_flow_out" >&2
  fi
else
  fail "plugin-local ssh-flow should succeed"
  sed -n '1,120p' "$tmp_flow_err" >&2
fi

if "$local_runner" ssh-guards >"$tmp_guards_out" 2>"$tmp_guards_err"; then
  if rg -q 'check-plugin-ssh-local\.sh' "$tmp_guards_out" \
    && rg -q 'check-plugin-ssh-runtime-smoke\.sh' "$tmp_guards_out" \
    && rg -q 'check-plugin-ssh-contracts\.sh' "$tmp_guards_out" \
    && rg -q 'check-plugin-ssh-fixtures\.sh' "$tmp_guards_out"; then
    pass "plugin-local ssh-guards prints the assembled ssh-only guard sequence"
  else
    fail "plugin-local ssh-guards output drifted from the expected ssh guard sequence"
    sed -n '1,160p' "$tmp_guards_out" >&2
  fi
else
  fail "plugin-local ssh-guards should succeed"
  sed -n '1,160p' "$tmp_guards_err" >&2
fi

if env PLUGIN_LOCAL_SSH_SKIP_LOCAL=1 "$local_runner" ssh-all --quiet >"$tmp_all_out" 2>"$tmp_all_err"; then
  if ! rg -q 'Plugin ssh local summary:' "$tmp_all_out" \
    && rg -q 'Plugin ssh runtime smoke summary: 2 pass, 0 fail' "$tmp_all_out" \
    && rg -q 'Plugin ssh contract summary: 20 pass, 0 fail' "$tmp_all_out" \
    && rg -q 'Plugin ssh fixture summary: 3 pass, 0 fail' "$tmp_all_out"; then
    pass "plugin-local ssh-all --quiet runs the assembled ssh-only guard sequence when local recursion is disabled"
  else
    fail "plugin-local ssh-all --quiet output drifted from the expected ssh aggregate guard sequence"
    sed -n '1,160p' "$tmp_all_out" >&2
  fi
else
  fail "plugin-local ssh-all --quiet should succeed when local recursion is disabled"
  sed -n '1,160p' "$tmp_all_err" >&2
fi

if "$local_runner" --help >"$tmp_help_out" 2>"$tmp_help_err"; then
  if rg -q 'ssh-flow' "$tmp_help_out" \
    && rg -q 'ssh-status' "$tmp_help_out" \
    && rg -q 'ssh-files' "$tmp_help_out" \
    && rg -q 'ssh-guards' "$tmp_help_out" \
    && rg -q 'ssh-all' "$tmp_help_out"; then
    pass "plugin-local help lists the first-party ssh workflow commands"
  else
    fail "plugin-local help output drifted from the expected first-party ssh workflow surface"
    sed -n '1,160p' "$tmp_help_out" >&2
  fi
else
  fail "plugin-local --help should succeed"
  sed -n '1,160p' "$tmp_help_err" >&2
fi

printf '[INFO] Plugin ssh local summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
