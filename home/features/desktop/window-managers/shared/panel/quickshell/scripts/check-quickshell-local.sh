#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
local_runner="${script_dir}/plugin-local.sh"
verify_runner="${script_dir}/quickshell-verify.sh"
shell_config="${script_dir}/../src/shell.qml"

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

show_excerpt() {
  local file="$1"
  local lines="${2:-160}"
  sed -n "1,${lines}p" "$file" >&2
}

run_capture() {
  local out_file="$1"
  local err_file="$2"
  shift 2
  "$@" >"$out_file" 2>"$err_file"
}

assert_patterns() {
  local file="$1"
  shift
  local pattern
  for pattern in "$@"; do
    if ! rg -q -- "$pattern" "$file"; then
      return 1
    fi
  done
  return 0
}

assert_no_pattern() {
  local file="$1"
  local pattern="$2"
  ! rg -q -- "$pattern" "$file"
}

if [[ ! -x "$local_runner" ]]; then
  echo "[FAIL] plugin-local runner not executable: ${local_runner}" >&2
  exit 1
fi

if [[ ! -x "$verify_runner" ]]; then
  echo "[FAIL] quickshell verifier not executable: ${verify_runner}" >&2
  exit 1
fi

if [[ ! -f "$shell_config" ]]; then
  echo "[FAIL] Missing Quickshell shell config: ${shell_config}" >&2
  exit 1
fi

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
tmp_live_out="$(mktemp)"
tmp_live_err="$(mktemp)"
tmp_verify_help_out="$(mktemp)"
tmp_verify_help_err="$(mktemp)"
tmp_help_out="$(mktemp)"
tmp_help_err="$(mktemp)"
trap 'rm -f "$tmp_status_out" "$tmp_status_err" "$tmp_status_quiet_out" "$tmp_status_quiet_err" "$tmp_files_out" "$tmp_files_err" "$tmp_flow_out" "$tmp_flow_err" "$tmp_guards_out" "$tmp_guards_err" "$tmp_all_out" "$tmp_all_err" "$tmp_live_out" "$tmp_live_err" "$tmp_verify_help_out" "$tmp_verify_help_err" "$tmp_help_out" "$tmp_help_err"' EXIT

if run_capture "$tmp_status_out" "$tmp_status_err" "$local_runner" quickshell-status --check; then
  if assert_patterns "$tmp_status_out" 'Quickshell status check passed'; then
    pass "plugin-local quickshell-status --check validates the live Quickshell workflow prerequisites"
  else
    fail "plugin-local quickshell-status --check did not report the expected success line"
    show_excerpt "$tmp_status_out" 120
  fi
else
  fail "plugin-local quickshell-status --check should succeed when the Quickshell service is active"
  show_excerpt "$tmp_status_err" 120
fi

if run_capture "$tmp_status_quiet_out" "$tmp_status_quiet_err" "$local_runner" quickshell-status --check --quiet; then
  if assert_patterns "$tmp_status_quiet_out" '^\[INFO\] Quickshell status:' 'Quickshell status check passed' \
    && assert_no_pattern "$tmp_status_quiet_out" '^Quickshell Runtime Status$'; then
    pass "plugin-local quickshell-status --check --quiet emits the compact Quickshell status line"
  else
    fail "plugin-local quickshell-status --check --quiet output drifted from the expected compact status form"
    show_excerpt "$tmp_status_quiet_out" 120
  fi
else
  fail "plugin-local quickshell-status --check --quiet should succeed"
  show_excerpt "$tmp_status_quiet_err" 120
fi

if run_capture "$tmp_files_out" "$tmp_files_err" "$local_runner" quickshell-files; then
  if assert_patterns "$tmp_files_out" '^shell_config=.*/src/shell\.qml$' 'guard_clipboard_contracts=.*/check-clipboard-contracts\.sh$' 'guard_panel_runtime=.*/scripts/vm/run-panel-vm-qa\.sh --vm both$' 'guard_panel_runtime_host_opt_out=.*/check-panel-runtime\.sh --repo-shell$' 'capture_validator=.*/check-panel-capture-artifacts\.sh$'; then
    pass "plugin-local quickshell-files prints the canonical Quickshell runtime file and guard paths"
  else
    fail "plugin-local quickshell-files output drifted from the expected Quickshell file summary"
    show_excerpt "$tmp_files_out" 120
  fi
else
  fail "plugin-local quickshell-files should succeed"
  show_excerpt "$tmp_files_err" 120
fi

if run_capture "$tmp_flow_out" "$tmp_flow_err" "$local_runner" quickshell-flow; then
  if assert_patterns "$tmp_flow_out" '^Quickshell Manual Flow$' 'scripts/quickshell-structure-verify\.sh' 'scripts/quickshell-structure-verify\.sh --vm both' 'scripts/vm/run-hyprland-panel-qa\.sh --mode panel' 'scripts/vm/run-niri-panel-qa\.sh --mode panel' 'check-panel-capture-artifacts\.sh --dir DIR' 'PLUGIN_LOCAL_QUICKSHELL_USE_VM=0' 'scripts/plugin-local\.sh quickshell-all'; then
    pass "plugin-local quickshell-flow documents the expected Quickshell runtime validation sequence"
  else
    fail "plugin-local quickshell-flow output drifted from the expected Quickshell manual flow"
    show_excerpt "$tmp_flow_out" 120
  fi
else
  fail "plugin-local quickshell-flow should succeed"
  show_excerpt "$tmp_flow_err" 120
fi

if run_capture "$tmp_guards_out" "$tmp_guards_err" "$local_runner" quickshell-guards; then
  if assert_patterns "$tmp_guards_out" \
    'quickshell-structure-verify\.sh$' \
    'quickshell-structure-verify\.sh --vm both$'; then
    pass "plugin-local quickshell-guards prints the assembled Quickshell guard sequence"
  else
    fail "plugin-local quickshell-guards output drifted from the expected Quickshell guard sequence"
    show_excerpt "$tmp_guards_out" 160
  fi
else
  fail "plugin-local quickshell-guards should succeed"
  show_excerpt "$tmp_guards_err" 160
fi

if run_capture "$tmp_all_out" "$tmp_all_err" "$local_runner" quickshell-all --quiet; then
  if assert_patterns "$tmp_all_out" \
    'Stage timing summary:' \
    'Quickshell startup smoke summary: 1 pass, 0 fail' \
    'Clipboard contract summary: 25 pass, 0 fail' \
    'Running transient repo-shell journal warning gate' \
    'Launcher smoke checks passed.' \
    'Aggregate artifacts saved to'; then
    pass "plugin-local quickshell-all --quiet runs the assembled Quickshell runtime guard sequence"
  else
    fail "plugin-local quickshell-all --quiet output drifted from the expected Quickshell aggregate guard sequence"
    show_excerpt "$tmp_all_out" 200
  fi
else
  fail "plugin-local quickshell-all --quiet should succeed"
  show_excerpt "$tmp_all_err" 200
fi

if run_capture "$tmp_live_out" "$tmp_live_err" "$local_runner" live-gates --quiet; then
  if assert_patterns "$tmp_live_out" \
    'Plugin runtime guard summary:' \
    'Quickshell startup smoke summary: 1 pass, 0 fail' \
    'Stage timing summary:' \
    'Aggregate artifacts saved to'; then
    pass "plugin-local live-gates --quiet runs the shared and live Quickshell gate sequence"
  else
    fail "plugin-local live-gates --quiet output drifted from the expected combined gate sequence"
    show_excerpt "$tmp_live_out" 240
  fi
else
  fail "plugin-local live-gates --quiet should succeed"
  show_excerpt "$tmp_live_err" 240
fi

if run_capture "$tmp_verify_help_out" "$tmp_verify_help_err" "$verify_runner" --help; then
  if assert_patterns "$tmp_verify_help_out" '^Usage: quickshell-verify\.sh \[--quiet\]$' 'scripts/plugin-local\.sh live-gates' \
    && assert_patterns "$verify_runner" 'plugin-local\.sh" live-gates'; then
    pass "quickshell-verify.sh documents and delegates to the Quickshell-first verification workflow"
  else
    fail "quickshell-verify.sh drifted from the expected Quickshell-first wrapper contract"
    show_excerpt "$tmp_verify_help_out" 160
  fi
else
  fail "quickshell-verify.sh --help should succeed"
  show_excerpt "$tmp_verify_help_err" 160
fi

if run_capture "$tmp_help_out" "$tmp_help_err" "$local_runner" --help; then
  if assert_patterns "$tmp_help_out" \
    'quickshell-flow' \
    'quickshell-status' \
    'quickshell-files' \
    'quickshell-guards' \
    'quickshell-all' \
    'live-gates'; then
    pass "plugin-local help lists the Quickshell workflow commands"
  else
    fail "plugin-local help output drifted from the expected Quickshell workflow surface"
    show_excerpt "$tmp_help_out" 160
  fi
else
  fail "plugin-local --help should succeed"
  show_excerpt "$tmp_help_err" 160
fi

printf '[INFO] Quickshell local summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
