#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
config_root="$(CDPATH= cd -- "${script_dir}/../config" && pwd -P)"

pass_count=0
fail_count=0
auto_cleanup=()

pass() {
  printf '[PASS] %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

cleanup() {
  local path
  for path in "${auto_cleanup[@]}"; do
    [[ -n "${path}" && -e "${path}" ]] && rm -rf -- "${path}"
  done
  return 0
}
trap cleanup EXIT

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 2
  fi
}

make_temp_home() {
  local home
  home="$(mktemp -d)"
  auto_cleanup+=("${home}")
  mkdir -p "${home}/.config/quickshell" "${home}/.local/state/quickshell"
  printf '{"themes":[]}\n' > "${home}/.config/quickshell/themes.json"
  printf '%s\n' "${home}"
}

make_temp_runtime() {
  local runtime_dir
  runtime_dir="$(mktemp -d)"
  auto_cleanup+=("${runtime_dir}")
  mkdir -p "${runtime_dir}/quickshell"
  chmod 700 "${runtime_dir}"
  printf '%s\n' "${runtime_dir}"
}

run_live_startup_smoke() {
  local home log_file pid elapsed output

  home="$(make_temp_home)"
  log_file="$(mktemp /tmp/quickshell-startup-smoke-live-XXXXXX.txt)"
  auto_cleanup+=("${log_file}")

  env HOME="${home}" quickshell -p "${config_root}/shell.qml" >"${log_file}" 2>&1 &
  pid=$!

  for elapsed in $(seq 1 20); do
    output="$(sed -n '1,220p' "${log_file}" 2>/dev/null || true)"
    if [[ "${output}" == *"Failed to load configuration"* || "${output}" == *" is not a type"* ]]; then
      kill "${pid}" >/dev/null 2>&1 || true
      wait "${pid}" >/dev/null 2>&1 || true
      printf '%s\n' "${output}" >&2
      return 1
    fi
    if [[ "${output}" == *"Configuration Loaded"* ]]; then
      kill "${pid}" >/dev/null 2>&1 || true
      wait "${pid}" >/dev/null 2>&1 || true
      return 0
    fi
    if ! kill -0 "${pid}" >/dev/null 2>&1; then
      wait "${pid}" >/dev/null 2>&1 || true
      printf '%s\n' "${output}" >&2
      return 1
    fi
    sleep 0.5
  done

  kill "${pid}" >/dev/null 2>&1 || true
  wait "${pid}" >/dev/null 2>&1 || true
  printf '%s\n' "$(sed -n '1,220p' "${log_file}" 2>/dev/null || true)" >&2
  return 1
}

run_headless_compile_smoke() {
  local home runtime_dir qml_path log_file output

  home="$(make_temp_home)"
  runtime_dir="$(make_temp_runtime)"
  qml_path="$(mktemp /tmp/quickshell-startup-smoke-headless-XXXXXX.qml)"
  log_file="$(mktemp /tmp/quickshell-startup-smoke-headless-log-XXXXXX.txt)"
  auto_cleanup+=("${qml_path}" "${log_file}")

  cat > "${qml_path}" <<QML
import Quickshell
import QtQuick

Scope {
  Component.onCompleted: {
    var component = Qt.createComponent("file://${config_root}/shell.qml");
    if (component.status !== Component.Ready) {
      console.log("COMPONENT_ERROR:" + component.errorString());
      Qt.quit();
      return;
    }
    console.log("COMPONENT_READY");
    Qt.quit();
  }
}
QML

  timeout 10s env HOME="${home}" XDG_RUNTIME_DIR="${runtime_dir}" QT_QPA_PLATFORM=offscreen \
    quickshell -p "${qml_path}" >"${log_file}" 2>&1 || true

  output="$(sed -n '1,220p' "${log_file}" 2>/dev/null || true)"
  if [[ "${output}" == *"COMPONENT_READY"* ]]; then
    return 0
  fi
  if [[ "${output}" == *"COMPONENT_ERROR:"* ]]; then
    if [[ "${output}" == *"No PanelWindow backend loaded."* ]] \
      && [[ "${output}" != *"Failed to load configuration"* ]] \
      && [[ "${output}" != *" is not a type"* ]]; then
      return 0
    fi
  fi

  printf '%s\n' "${output}" >&2
  return 1
}

main() {
  require_cmd quickshell
  require_cmd mktemp
  require_cmd timeout
  require_cmd sed
  require_cmd sleep

  local mode="headless"
  if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]; then
    mode="live"
  fi

  if [[ "${mode}" == "live" ]]; then
    if run_live_startup_smoke; then
      pass "quickshell startup smoke launches the repo shell configuration in a live session"
    else
      fail "quickshell startup smoke launches the repo shell configuration in a live session"
    fi
  else
    if run_headless_compile_smoke; then
      pass "quickshell startup smoke resolves the repo shell configuration in headless mode"
    else
      fail "quickshell startup smoke resolves the repo shell configuration in headless mode"
    fi
  fi

  printf '[INFO] Quickshell startup smoke summary: %d pass, %d fail\n' "${pass_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"
