#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
services_dir="${script_dir}/../src/services"
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
  require_cmd bash
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
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left | length')" == "6" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[0].widgetType')" == "logo" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[1].widgetType')" == "workspaces" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[2].widgetType')" == "windowTitle" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[3].widgetType')" == "taskbar" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[4].widgetType')" == "cpuStatus" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[4].settings.displayMode')" == "auto" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[4].settings.valueStyle')" == "percent" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[5].widgetType')" == "ramStatus" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[5].settings.displayMode')" == "auto" ]] \
    && [[ "$(printf '%s' "${new_bar_json}" | jq -r '.left[5].settings.valueStyle')" == "usage" ]] \
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

  local media_migration_output media_migration_json
  media_migration_output="$(run_harness "cava to mediaBar migration" '
    var normalized = Config.normalizeBarConfigs([
      {
        id: "bar-media",
        name: "Media",
        enabled: true,
        position: "top",
        sectionWidgets: {
          center: [
            { instanceId: "clock-1", widgetType: "dateTime", enabled: true, settings: {} },
            { instanceId: "media-1", widgetType: "mediaBar", enabled: true, settings: { displayMode: "full", maxTextWidth: 222 } },
            { instanceId: "cava-1", widgetType: "cava", enabled: true, settings: { barCount: 12 } }
          ]
        }
      },
      {
        id: "bar-cava-only",
        name: "Cava Only",
        enabled: true,
        position: "bottom",
        sectionWidgets: {
          center: [
            { instanceId: "cava-2", widgetType: "cava", enabled: true, settings: { barCount: 6 } }
          ]
        }
      }
    ], {});
    console.log("CONTRACT:" + JSON.stringify(normalized));
    Qt.quit();
  ')" || true

  media_migration_json="$(printf '%s\n' "${media_migration_output}" | sed -n 's/^.*CONTRACT://p' | tail -n 1)"
  if [[ -n "${media_migration_json}" ]] \
    && [[ "$(printf '%s' "${media_migration_json}" | jq -r '.[0].sectionWidgets.center | map(select(.widgetType == "cava")) | length')" == "0" ]] \
    && [[ "$(printf '%s' "${media_migration_json}" | jq -r '.[0].sectionWidgets.center | map(select(.widgetType == "mediaBar")) | length')" == "1" ]] \
    && [[ "$(printf '%s' "${media_migration_json}" | jq -r '.[0].sectionWidgets.center[] | select(.widgetType == "mediaBar").settings.displayMode')" == "full" ]] \
    && [[ "$(printf '%s' "${media_migration_json}" | jq -r '.[0].sectionWidgets.center[] | select(.widgetType == "mediaBar").settings.maxTextWidth')" == "222" ]] \
    && [[ "$(printf '%s' "${media_migration_json}" | jq -r '.[0].sectionWidgets.center[] | select(.widgetType == "mediaBar").settings.showVisualizer')" == "true" ]] \
    && [[ "$(printf '%s' "${media_migration_json}" | jq -r '.[0].sectionWidgets.center[] | select(.widgetType == "mediaBar").settings.visualizerBars')" == "12" ]] \
    && [[ "$(printf '%s' "${media_migration_json}" | jq -r '.[1].sectionWidgets.center | map(select(.widgetType == "cava")) | length')" == "0" ]] \
    && [[ "$(printf '%s' "${media_migration_json}" | jq -r '.[1].sectionWidgets.center | map(select(.widgetType == "mediaBar")) | length')" == "1" ]] \
    && [[ "$(printf '%s' "${media_migration_json}" | jq -r '.[1].sectionWidgets.center[0].settings.showVisualizer')" == "true" ]] \
    && [[ "$(printf '%s' "${media_migration_json}" | jq -r '.[1].sectionWidgets.center[0].settings.visualizerBars')" == "6" ]]; then
    pass "Legacy cava widgets migrate into mediaBar settings"
  else
    fail "Legacy cava widgets migrate into mediaBar settings"
  fi

  local vpn_profiles_output vpn_profiles_json
  vpn_profiles_output="$(run_harness "vpn saved profile normalization" '
    var profiles = NetworkService.buildVpnProfiles(
      "uuid-active:Work VPN:vpn\nuuid-idle:Work VPN:vpn\nuuid-wire:Lab Tunnel:wireguard",
      "uuid-active:Work VPN:vpn:tun0:activated\nuuid-missing:Ad Hoc:vpn:tun9:activated"
    );
    console.log("CONTRACT:" + JSON.stringify({
      profiles: profiles,
      activeCount: profiles.filter(function(profile) { return !!profile.active; }).length,
      inactiveCount: profiles.filter(function(profile) { return !profile.active; }).length
    }));
    Qt.quit();
  ')" || true

  vpn_profiles_json="$(printf '%s\n' "${vpn_profiles_output}" | sed -n 's/^.*CONTRACT://p' | tail -n 1)"
  if [[ -n "${vpn_profiles_json}" ]] \
    && [[ "$(printf '%s' "${vpn_profiles_json}" | jq -r '.profiles | length')" == "4" ]] \
    && [[ "$(printf '%s' "${vpn_profiles_json}" | jq -r '.activeCount')" == "2" ]] \
    && [[ "$(printf '%s' "${vpn_profiles_json}" | jq -r '.inactiveCount')" == "2" ]] \
    && [[ "$(printf '%s' "${vpn_profiles_json}" | jq -r '.profiles[] | select(.uuid == "uuid-active").active')" == "true" ]] \
    && [[ "$(printf '%s' "${vpn_profiles_json}" | jq -r '.profiles[] | select(.uuid == "uuid-active").device')" == "tun0" ]] \
    && [[ "$(printf '%s' "${vpn_profiles_json}" | jq -r '.profiles[] | select(.uuid == "uuid-idle").name')" == "Work VPN" ]] \
    && [[ "$(printf '%s' "${vpn_profiles_json}" | jq -r '.profiles[] | select(.uuid == "uuid-wire").type')" == "wireguard" ]] \
    && [[ "$(printf '%s' "${vpn_profiles_json}" | jq -r '.profiles[] | select(.uuid == "uuid-missing").active')" == "true" ]]; then
    pass "VPN saved profiles merge catalog entries and active sessions by UUID"
  else
    fail "VPN saved profiles merge catalog entries and active sessions by UUID"
  fi

  local vpn_grouping_output vpn_grouping_json
  vpn_grouping_output="$(run_harness "vpn saved profile grouping" '
    NetworkService.vpnProfiles = [
      { uuid: "uuid-1", name: "Shared", type: "vpn", device: "", state: "", active: false },
      { uuid: "uuid-2", name: "Shared", type: "vpn", device: "tun2", state: "activated", active: true }
    ];
    console.log("CONTRACT:" + JSON.stringify({
      hasSavedProfiles: NetworkService.vpnHasSavedProfiles,
      profileCount: NetworkService.vpnProfileCount,
      activeCount: NetworkService.vpnActiveProfiles.length,
      inactiveCount: NetworkService.vpnInactiveProfiles.length,
      activeUuid: NetworkService.vpnActiveProfiles[0].uuid,
      inactiveUuid: NetworkService.vpnInactiveProfiles[0].uuid
    }));
    Qt.quit();
  ')" || true

  vpn_grouping_json="$(printf '%s\n' "${vpn_grouping_output}" | sed -n 's/^.*CONTRACT://p' | tail -n 1)"
  if [[ -n "${vpn_grouping_json}" ]] \
    && [[ "$(printf '%s' "${vpn_grouping_json}" | jq -r '.hasSavedProfiles')" == "true" ]] \
    && [[ "$(printf '%s' "${vpn_grouping_json}" | jq -r '.profileCount')" == "2" ]] \
    && [[ "$(printf '%s' "${vpn_grouping_json}" | jq -r '.activeCount')" == "1" ]] \
    && [[ "$(printf '%s' "${vpn_grouping_json}" | jq -r '.inactiveCount')" == "1" ]] \
    && [[ "$(printf '%s' "${vpn_grouping_json}" | jq -r '.activeUuid')" == "uuid-2" ]] \
    && [[ "$(printf '%s' "${vpn_grouping_json}" | jq -r '.inactiveUuid')" == "uuid-1" ]]; then
    pass "VPN saved profile grouping preserves duplicate names and separates active rows"
  else
    fail "VPN saved profile grouping preserves duplicate names and separates active rows"
  fi

  if bash "${script_dir}/check-network-vpn-contracts.sh"; then
    pass "VPN hub structural contracts stay wired across registry, shell, and popup layers"
  else
    fail "VPN hub structural contracts stay wired across registry, shell, and popup layers"
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
