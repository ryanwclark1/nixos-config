#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
plugin_dir="${script_dir}/../examples/plugins/docker-manager"
doctor_script="${script_dir}/plugin-doctor.sh"
local_runner="${script_dir}/plugin-local.sh"
plugin_id="docker.manager"

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
  echo '[FAIL] jq is required for docker-manager local checks' >&2
  exit 1
fi

if [[ ! -x "$doctor_script" ]]; then
  echo "[FAIL] plugin-doctor script not executable: ${doctor_script}" >&2
  exit 1
fi

if [[ ! -d "$plugin_dir" ]]; then
  echo "[FAIL] Missing docker-manager plugin directory: ${plugin_dir}" >&2
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

cp -R "$plugin_dir" "${tmp_plugins}/docker-manager"

if "$doctor_script" --json "$tmp_plugins" >"$tmp_json" 2>/tmp/plugin_docker_local.err; then
  if jq -e --arg id "$plugin_id" '
    .summary.fail == 0
    and .summary.pass == 1
    and ([.entries[] | select(.status == "PASS" and .name == "docker-manager")] | length) == 1
    and .pluginsDir != ""
  ' "$tmp_json" >/dev/null 2>&1; then
    pass "plugin-doctor validates the shipped docker-manager plugin directory in isolation"
  else
    fail "plugin-doctor json output for docker-manager is missing the expected success payload"
    sed -n '1,120p' "$tmp_json" >&2
  fi
else
  fail "plugin-doctor should pass for the shipped docker-manager plugin directory"
  sed -n '1,120p' /tmp/plugin_docker_local.err >&2
fi

if jq -e --arg id "$plugin_id" '.id == $id and .type == "multi" and .entryPoints.barWidget == "BarWidget.qml" and .entryPoints.daemon == "Daemon.qml" and .entryPoints.settings == "Settings.qml"' "${plugin_dir}/manifest.json" >/dev/null 2>&1; then
  pass "docker-manager manifest keeps the expected shipped entry points"
else
  fail "docker-manager manifest drifted from the expected shipped entry points"
fi

if "$local_runner" docker-status --check >"$tmp_status_out" 2>"$tmp_status_err"; then
  if rg -q 'Docker Manager status check passed' "$tmp_status_out"; then
    pass "plugin-local docker-status --check validates docker-manager prerequisites"
  else
    fail "plugin-local docker-status --check did not report the expected success line"
    sed -n '1,120p' "$tmp_status_out" >&2
  fi
else
  fail "plugin-local docker-status --check should succeed"
  sed -n '1,120p' "$tmp_status_err" >&2
fi

if "$local_runner" docker-status --check --quiet >"$tmp_status_quiet_out" 2>"$tmp_status_quiet_err"; then
  if rg -q '^\[INFO\] Docker Manager status:' "$tmp_status_quiet_out" \
    && ! rg -q '^Docker Manager Local Status$' "$tmp_status_quiet_out" \
    && rg -q 'Docker Manager status check passed' "$tmp_status_quiet_out"; then
    pass "plugin-local docker-status --check --quiet emits the compact docker-manager status line"
  else
    fail "plugin-local docker-status --check --quiet output drifted from the expected compact status form"
    sed -n '1,120p' "$tmp_status_quiet_out" >&2
  fi
else
  fail "plugin-local docker-status --check --quiet should succeed"
  sed -n '1,120p' "$tmp_status_quiet_err" >&2
fi

if "$local_runner" docker-files >"$tmp_files_out" 2>"$tmp_files_err"; then
  if rg -q '^plugin_id=docker\.manager$' "$tmp_files_out" \
    && rg -q 'guard_runtime_smoke=.*/check-plugin-docker-manager-runtime-smoke\.sh$' "$tmp_files_out"; then
    pass "plugin-local docker-files prints the canonical docker-manager file and guard paths"
  else
    fail "plugin-local docker-files output drifted from the expected docker-manager file summary"
    sed -n '1,120p' "$tmp_files_out" >&2
  fi
else
  fail "plugin-local docker-files should succeed"
  sed -n '1,120p' "$tmp_files_err" >&2
fi

if "$local_runner" docker-flow >"$tmp_flow_out" 2>"$tmp_flow_err"; then
  if rg -q '^Docker Manager Manual Flow$' "$tmp_flow_out" \
    && rg -q 'plugin becomes degraded without crashing the bar' "$tmp_flow_out"; then
    pass "plugin-local docker-flow documents the expected docker-manager manual validation sequence"
  else
    fail "plugin-local docker-flow output drifted from the expected docker-manager manual flow"
    sed -n '1,120p' "$tmp_flow_out" >&2
  fi
else
  fail "plugin-local docker-flow should succeed"
  sed -n '1,120p' "$tmp_flow_err" >&2
fi

if "$local_runner" docker-guards >"$tmp_guards_out" 2>"$tmp_guards_err"; then
  if rg -q 'check-plugin-docker-manager-local\.sh' "$tmp_guards_out" \
    && rg -q 'check-plugin-docker-manager-runtime-smoke\.sh' "$tmp_guards_out" \
    && rg -q 'check-plugin-docker-manager-contracts\.sh' "$tmp_guards_out" \
    && rg -q 'check-plugin-docker-manager-diagnostics\.sh' "$tmp_guards_out"; then
    pass "plugin-local docker-guards prints the assembled docker-manager guard sequence"
  else
    fail "plugin-local docker-guards output drifted from the expected docker-manager guard sequence"
    sed -n '1,120p' "$tmp_guards_out" >&2
  fi
else
  fail "plugin-local docker-guards should succeed"
  sed -n '1,120p' "$tmp_guards_err" >&2
fi

if env PLUGIN_LOCAL_DOCKER_SKIP_LOCAL=1 "$local_runner" docker-all --quiet >"$tmp_all_out" 2>"$tmp_all_err"; then
  if ! rg -q 'Plugin docker local summary:' "$tmp_all_out" \
    && rg -q 'Plugin docker runtime smoke summary: 2 pass, 0 fail' "$tmp_all_out" \
    && rg -q 'Docker-manager plugin contract summary: 28 pass, 0 fail' "$tmp_all_out" \
    && rg -q 'Plugin docker diagnostics summary:' "$tmp_all_out"; then
    pass "plugin-local docker-all --quiet runs the assembled docker-manager guard sequence when local recursion is disabled"
  else
    fail "plugin-local docker-all --quiet output drifted from the expected docker-manager aggregate guard sequence"
    sed -n '1,160p' "$tmp_all_out" >&2
  fi
else
  fail "plugin-local docker-all --quiet should succeed when local recursion is disabled"
  sed -n '1,160p' "$tmp_all_err" >&2
fi

if "$local_runner" --help >"$tmp_help_out" 2>"$tmp_help_err"; then
  if rg -q 'install-docker-manager' "$tmp_help_out" \
    && rg -q 'docker-status' "$tmp_help_out" \
    && rg -q 'docker-guards' "$tmp_help_out" \
    && rg -q 'docker-all' "$tmp_help_out"; then
    pass "plugin-local help lists the docker-manager workflow commands"
  else
    fail "plugin-local help output drifted from the expected docker-manager command list"
    sed -n '1,160p' "$tmp_help_out" >&2
  fi
else
  fail "plugin-local --help should succeed"
  sed -n '1,120p' "$tmp_help_err" >&2
fi

printf '[INFO] Plugin docker local summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
