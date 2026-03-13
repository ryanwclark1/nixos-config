#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pass_count=0
fail_count=0
warn_count=0

pass() {
  printf '[PASS] %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

warn() {
  printf '[WARN] %s\n' "$1"
  warn_count=$((warn_count + 1))
}

run_guard_check() {
  local guard_script="${script_dir}/check-compositor-guards.sh"
  if [[ -x "${guard_script}" ]]; then
    if "${guard_script}" >/dev/null; then
      pass "Compositor guard check"
    else
      fail "Compositor guard check"
    fi
  else
    warn "Guard script not executable: ${guard_script}"
  fi
}

detect_compositor() {
  local desktop session
  desktop="${XDG_CURRENT_DESKTOP:-}"
  session="${DESKTOP_SESSION:-}"

  if [[ "${desktop}${session}" =~ [Nn]iri ]]; then
    printf 'niri\n'
    return
  fi
  if [[ "${desktop}${session}" =~ [Hh]yprland ]]; then
    printf 'hyprland\n'
    return
  fi
  if [[ -n "${NIRI_SOCKET:-}" ]]; then
    printf 'niri\n'
    return
  fi
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    printf 'hyprland\n'
    return
  fi
  printf 'unknown\n'
}

check_hyprland() {
  if ! command -v hyprctl >/dev/null 2>&1; then
    fail "hyprctl unavailable while compositor detected as Hyprland"
    return
  fi
  if ! command -v jq >/dev/null 2>&1; then
    fail "jq unavailable for Hyprland smoke checks"
    return
  fi

  local ws_raw active_raw
  ws_raw="$(hyprctl workspaces -j 2>/dev/null || true)"
  active_raw="$(hyprctl activeworkspace -j 2>/dev/null || true)"

  if [[ -z "${ws_raw}" ]]; then
    fail "Hyprland workspaces command returned empty output"
  elif printf '%s' "${ws_raw}" | jq -e '.' >/dev/null 2>&1; then
    pass "Hyprland workspaces JSON parses"
  else
    fail "Hyprland workspaces JSON parse failed"
  fi

  if [[ -z "${active_raw}" ]]; then
    fail "Hyprland active workspace command returned empty output"
  elif printf '%s' "${active_raw}" | jq -e '.' >/dev/null 2>&1; then
    pass "Hyprland active workspace JSON parses"
  else
    fail "Hyprland active workspace JSON parse failed"
  fi
}

check_niri() {
  if ! command -v niri >/dev/null 2>&1; then
    fail "niri command unavailable while compositor detected as Niri"
    return
  fi
  if ! command -v jq >/dev/null 2>&1; then
    fail "jq unavailable for Niri smoke checks"
    return
  fi

  local raw active_name active_idx
  raw="$(niri msg -j workspaces 2>/dev/null || true)"

  if printf '%s' "${raw}" | jq -e '.' >/dev/null 2>&1; then
    pass "Niri workspaces JSON parses"
  else
    fail "Niri workspaces JSON parse failed"
    return
  fi

  active_name="$(printf '%s' "${raw}" | jq -r '(if type == "array" then . else (.workspaces // []) end)[] | select(.is_active == true or .active == true or .is_focused == true or .focused == true) | (.name // .idx // .id // .index // empty)' | head -n1 || true)"
  if [[ -n "${active_name}" ]]; then
    pass "Niri active workspace extracted (${active_name})"
  else
    warn "Niri active workspace not found in workspaces payload"
  fi

  active_idx="$(printf '%s' "${raw}" | jq -r '(if type == "array" then . else (.workspaces // []) end)[] | select(.is_active == true or .active == true or .is_focused == true or .focused == true) | (.idx // .id // .index // empty)' | head -n1 || true)"
  if [[ -n "${active_idx}" ]]; then
    if niri msg action focus-workspace "${active_idx}" >/dev/null 2>&1; then
      pass "Niri focus-workspace action accepted for active workspace (${active_idx})"
    else
      warn "Niri focus-workspace action failed for active workspace (${active_idx})"
    fi
  fi
}

main() {
  run_guard_check

  local compositor
  compositor="$(detect_compositor)"
  printf '[INFO] Detected compositor: %s\n' "${compositor}"

  case "${compositor}" in
    hyprland)
      check_hyprland
      ;;
    niri)
      check_niri
      ;;
    unknown)
      warn "Unknown compositor from environment; skipping compositor-specific runtime checks"
      ;;
  esac

  printf '[INFO] Summary: %d pass, %d warn, %d fail\n' "${pass_count}" "${warn_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"
