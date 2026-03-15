#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
services_dir="${script_dir}/../config/services"
services_url="file://${services_dir}"

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
  for path in "${auto_cleanup[@]:-}"; do
    [[ -e "${path}" ]] && rm -rf -- "${path}"
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
  mkdir -p "${home}/.local/state/quickshell" "${home}/.config/quickshell"
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

run_harness() {
  local name="$1"
  local qml_body="$2"
  local home runtime_dir qml_path log_file

  home="$(make_temp_home)"
  runtime_dir="$(make_temp_runtime)"
  qml_path="$(mktemp /tmp/panel-config-contract-XXXXXX.qml)"
  auto_cleanup+=("${qml_path}")
  log_file="$(mktemp /tmp/panel-config-contract-log-XXXXXX.txt)"
  auto_cleanup+=("${log_file}")

  cat > "${qml_path}" <<QML
import Quickshell
import QtQuick
import "${services_url}"

Scope {
  Component.onCompleted: {
${qml_body}
  }
}
QML

  set +e
  timeout 5s env -u WAYLAND_DISPLAY HOME="${home}" XDG_RUNTIME_DIR="${runtime_dir}" QT_QPA_PLATFORM=offscreen \
    quickshell -p "${qml_path}" --no-duplicate > "${log_file}" 2>&1
  local exit_code=$?
  set -e

  if [[ ${exit_code} -ne 0 && ${exit_code} -ne 124 ]]; then
    fail "${name}"
    sed -n '1,200p' "${log_file}" >&2
    return 1
  fi

  sed -n '1,200p' "${log_file}"
  return 0
}

main() {
  require_cmd quickshell
  require_cmd jq
  require_cmd sed
  require_cmd mktemp
  require_cmd timeout

  local defaults_output defaults_json
  defaults_output="$(run_harness "stat widget default settings" '
    console.log("CONTRACT:" + JSON.stringify({
      cpu: BarWidgetRegistry.defaultSettings("cpuStatus"),
      ram: BarWidgetRegistry.defaultSettings("ramStatus"),
      gpu: BarWidgetRegistry.defaultSettings("gpuStatus")
    }));
    Qt.quit();
  ')" || true

  defaults_json="$(printf '%s\n' "${defaults_output}" | sed -n 's/^.*CONTRACT://p' | tail -n 1)"
  if [[ -n "${defaults_json}" ]] \
    && [[ "$(printf '%s' "${defaults_json}" | jq -r '.cpu.displayMode')" == "auto" ]] \
    && [[ "$(printf '%s' "${defaults_json}" | jq -r '.cpu.valueStyle')" == "percent" ]] \
    && [[ "$(printf '%s' "${defaults_json}" | jq -r '.ram.displayMode')" == "auto" ]] \
    && [[ "$(printf '%s' "${defaults_json}" | jq -r '.ram.valueStyle')" == "usage" ]] \
    && [[ "$(printf '%s' "${defaults_json}" | jq -r '.gpu.displayMode')" == "auto" ]] \
    && [[ "$(printf '%s' "${defaults_json}" | jq -r '.gpu.valueStyle')" == "percent" ]]; then
    pass "Stat widget defaults expose displayMode/valueStyle defaults"
  else
    fail "Stat widget defaults expose displayMode/valueStyle defaults"
  fi

  local normalized_output normalized_json
  normalized_output="$(run_harness "legacy system monitor migration" '
    var normalized = Config.normalizeBarConfigs([
      {
        id: "bar-1",
        name: "Main",
        enabled: true,
        position: "left",
        sectionWidgets: {
          left: ["systemMonitor"]
        }
      }
    ], {});
    console.log("CONTRACT:" + JSON.stringify(normalized));
    Qt.quit();
  ')" || true

  normalized_json="$(printf '%s\n' "${normalized_output}" | sed -n 's/^.*CONTRACT://p' | tail -n 1)"
  if [[ -n "${normalized_json}" ]] \
    && [[ "$(printf '%s' "${normalized_json}" | jq -r '.[0].sectionWidgets.left | length')" == "2" ]] \
    && [[ "$(printf '%s' "${normalized_json}" | jq -r '.[0].sectionWidgets.left[0].widgetType')" == "cpuStatus" ]] \
    && [[ "$(printf '%s' "${normalized_json}" | jq -r '.[0].sectionWidgets.left[0].settings.displayMode')" == "auto" ]] \
    && [[ "$(printf '%s' "${normalized_json}" | jq -r '.[0].sectionWidgets.left[0].settings.valueStyle')" == "percent" ]] \
    && [[ "$(printf '%s' "${normalized_json}" | jq -r '.[0].sectionWidgets.left[1].widgetType')" == "ramStatus" ]]; then
    pass "Legacy systemMonitor expands into cpuStatus + ramStatus"
  else
    fail "Legacy systemMonitor expands into cpuStatus + ramStatus"
  fi

  local new_bar_output new_bar_json
  new_bar_output="$(run_harness "default bar composition" '
    console.log("CONTRACT:" + JSON.stringify(Config.defaultBarSectionWidgets()));
    Qt.quit();
  ')" || true

  new_bar_json="$(printf '%s\n' "${new_bar_output}" | sed -n 's/^.*CONTRACT://p' | tail -n 1)"
  if [[ -n "${new_bar_json}" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[4].widgetType')" == "taskbar" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[5].widgetType')" == "cpuStatus" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[5].settings.displayMode')" == "auto" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[5].settings.valueStyle')" == "percent" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[6].widgetType')" == "ramStatus" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[6].settings.displayMode')" == "auto" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[6].settings.valueStyle')" == "usage" ]] \
    && ! printf '%s' "${new_bar_json}" | jq -e '.. | objects | select(.widgetType? == "systemMonitor")' >/dev/null; then
    pass "Default bar composition uses separated stat widgets"
  else
    fail "Default bar composition uses separated stat widgets"
  fi

  local sparse_output sparse_json
  sparse_output="$(run_harness "sparse stat widget settings normalization" '
    var normalized = Config.normalizeBarConfigs([
      {
        id: "bar-2",
        name: "Sparse",
        enabled: true,
        position: "top",
        sectionWidgets: {
          left: [
            { instanceId: "cpu-1", widgetType: "cpuStatus", enabled: true, settings: {} },
            { instanceId: "ram-1", widgetType: "ramStatus", enabled: true, settings: { displayMode: "icon" } },
            { instanceId: "gpu-1", widgetType: "gpuStatus", enabled: true, settings: { valueStyle: "usageTemp" } }
          ]
        }
      }
    ], {});
    console.log("CONTRACT:" + JSON.stringify(normalized));
    Qt.quit();
  ')" || true

  sparse_json="$(printf '%s\n' "${sparse_output}" | sed -n 's/^.*CONTRACT://p' | tail -n 1)"
  if [[ -n "${sparse_json}" ]] \
    && [[ "$(printf '%s' "${sparse_json}" | jq -r '.[0].sectionWidgets.left[0].settings.displayMode')" == "auto" ]] \
    && [[ "$(printf '%s' "${sparse_json}" | jq -r '.[0].sectionWidgets.left[0].settings.valueStyle')" == "percent" ]] \
    && [[ "$(printf '%s' "${sparse_json}" | jq -r '.[0].sectionWidgets.left[1].settings.displayMode')" == "icon" ]] \
    && [[ "$(printf '%s' "${sparse_json}" | jq -r '.[0].sectionWidgets.left[1].settings.valueStyle')" == "usage" ]] \
    && [[ "$(printf '%s' "${sparse_json}" | jq -r '.[0].sectionWidgets.left[2].settings.displayMode')" == "auto" ]] \
    && [[ "$(printf '%s' "${sparse_json}" | jq -r '.[0].sectionWidgets.left[2].settings.valueStyle')" == "usageTemp" ]]; then
    pass "Sparse stat widget settings inherit missing defaults"
  else
    fail "Sparse stat widget settings inherit missing defaults"
  fi

  printf '[INFO] Summary: %d pass, %d fail\n' "${pass_count}" "${fail_count}"
  if (( fail_count == 0 )); then
    return 0
  fi

  return 1
}

if main "$@"; then
  exit 0
fi

exit 1
