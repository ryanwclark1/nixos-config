#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
config_dir="${QS_CONFIG_DIR:-${script_dir}/../src}"
root_qml="${config_dir}/shell.qml"
declare -i pass_count=0
declare -i fail_count=0
declare -i warn_count=0
declare -i skip_count=0
run_shell_matrix=1
run_management_harnesses_only=0

auto_cleanup=()

pass() {
  printf '[PASS] %s\n' "$1"
  pass_count=$((pass_count + 1))
}

warn() {
  printf '[WARN] %s\n' "$1"
  warn_count=$((warn_count + 1))
}

skip() {
  printf '[SKIP] %s\n' "$1"
  skip_count=$((skip_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

print_log_excerpt() {
  local log_file="$1"
  if ! grep -E '^( ERROR: Failed to load configuration| ERROR:   caused by )' "${log_file}" >&2; then
    sed -n '1,80p' "${log_file}" >&2
  fi
}

cleanup() {
  local path
  for path in "${auto_cleanup[@]:-}"; do
    [[ -e "${path}" ]] && rm -rf -- "${path}"
  done
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
  printf '{"themes":[]}' > "${home}/.config/quickshell/themes.json"
  printf '%s\n' "$home"
}

make_temp_runtime() {
  local runtime_dir
  runtime_dir="$(mktemp -d)"
  auto_cleanup+=("${runtime_dir}")
  mkdir -p "${runtime_dir}/quickshell"
  chmod 700 "${runtime_dir}"
  printf '%s\n' "$runtime_dir"
}

run_qml_case() {
  local label="$1"
  local qml_path="$2"
  local home="$3"
  local runtime_dir="$4"
  local log_file="${home}/$(basename "${qml_path}").log"
  local exit_code=0

  set +e
  timeout 5s env -u WAYLAND_DISPLAY -u DISPLAY HOME="${home}" XDG_RUNTIME_DIR="${runtime_dir}" QT_QPA_PLATFORM=offscreen quickshell -p "${qml_path}" --no-duplicate > "${log_file}" 2>&1
  exit_code=$?
  set -e

  if grep -q 'Configuration Loaded' "${log_file}" && [[ ${exit_code} -eq 124 || ${exit_code} -eq 0 ]]; then
    pass "${label}"
    return 0
  fi

  if grep -q 'No PanelWindow backend loaded' "${log_file}"; then
    skip "${label}: no PanelWindow backend available in this environment"
    print_log_excerpt "${log_file}"
    return 0
  fi

  fail "${label}"
  sed -n '1,200p' "${log_file}" >&2
  return 1
}

write_config() {
  local home="$1"
  local payload="$2"
  printf '%s\n' "$payload" > "${home}/.local/state/quickshell/config.json"
}

run_shell_case() {
  local label="$1"
  local payload="$2"
  local home
  local runtime_dir
  home="$(make_temp_home)"
  runtime_dir="$(make_temp_runtime)"
  write_config "${home}" "${payload}"
  run_qml_case "shell matrix: ${label}" "${root_qml}" "${home}" "${runtime_dir}"
}

write_tab_harnesses() {
  local harness_dir="$1"
  local bar_tab_qml="${harness_dir}/bar-tab-harness.qml"
  local bar_widgets_qml="${harness_dir}/bar-widgets-harness.qml"

  mkdir -p "${harness_dir}/features/settings"
  ln -s "${config_dir}/services" "${harness_dir}/services"
  ln -s "${config_dir}/widgets" "${harness_dir}/widgets"
  ln -s "${config_dir}/features/settings/components" "${harness_dir}/features/settings/components"

  cat > "${bar_tab_qml}" <<QML
import Quickshell
import QtQuick
import QtQuick.Layouts
import "./services"
import "./features/settings/components/tabs"

PanelWindow {
  visible: true
  color: "transparent"
  implicitWidth: 900
  implicitHeight: 720

  Rectangle {
    anchors.fill: parent
    color: Colors.background

    BarTab {
      anchors.fill: parent
      tabId: "bars"
      compactMode: true
      tightSpacing: false
    }
  }
}
QML

  cat > "${bar_widgets_qml}" <<QML
import Quickshell
import QtQuick
import QtQuick.Layouts
import "./services"
import "./features/settings/components/tabs"

PanelWindow {
  visible: true
  color: "transparent"
  implicitWidth: 960
  implicitHeight: 760

  Rectangle {
    anchors.fill: parent
    color: Colors.background

    BarWidgetsTab {
      anchors.fill: parent
      tabId: "bar-widgets"
      compactMode: true
      tightSpacing: false
      widgetPickerOpen: true
      widgetSettingsOpen: true
      settingsSection: "left"
      settingsInstanceId: "cpu-left-1"
    }
  }
}
QML
}

run_management_harnesses() {
  local home harness_dir runtime_dir
  home="$(make_temp_home)"
  runtime_dir="$(make_temp_runtime)"
  harness_dir="$(mktemp -d)"
  auto_cleanup+=("${harness_dir}")

  write_config "${home}" '{
    "dock": { "enabled": true, "position": "right" },
    "bars": {
      "selectedBarId": "bar-left",
      "configs": [
        {
          "id": "bar-left",
          "name": "Left Bar",
          "enabled": true,
          "position": "left",
          "displayMode": "all",
          "height": 38,
          "floating": true,
          "margin": 12,
          "opacity": 0.85,
          "sectionWidgets": {
            "left": [
              { "instanceId": "cpu-left-1", "widgetType": "cpuStatus", "enabled": true, "settings": { "displayMode": "compact" } },
              { "instanceId": "spacer-left-1", "widgetType": "spacer", "enabled": true, "settings": { "size": 48 } },
              { "instanceId": "logo-left-1", "widgetType": "logo", "enabled": true, "settings": {} }
            ],
            "center": [
              { "instanceId": "date-center-1", "widgetType": "dateTime", "enabled": true, "settings": {} }
            ],
            "right": [
              { "instanceId": "notif-right-1", "widgetType": "notifications", "enabled": true, "settings": {} }
            ]
          }
        },
        {
          "id": "bar-bottom",
          "name": "Bottom Bar",
          "enabled": true,
          "position": "bottom",
          "displayMode": "primary",
          "height": 38,
          "floating": true,
          "margin": 12,
          "opacity": 0.85
        }
      ]
    }
  }'

  write_tab_harnesses "${harness_dir}"
  run_qml_case 'management harness: BarTab' "${harness_dir}/bar-tab-harness.qml" "${home}" "${runtime_dir}"
  run_qml_case 'management harness: BarWidgetsTab' "${harness_dir}/bar-widgets-harness.qml" "${home}" "${runtime_dir}"
}

main() {
  require_cmd quickshell
  require_cmd timeout
  require_cmd mktemp
  require_cmd grep
  require_cmd sed

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-shell-matrix)
        run_shell_matrix=0
        shift
        ;;
      --management-only)
        run_shell_matrix=0
        run_management_harnesses_only=1
        shift
        ;;
      -h|--help)
        cat <<'EOF'
Usage: check-multibar-smoke.sh [--skip-shell-matrix] [--management-only]

Run synthetic multibar verification cases.
  --skip-shell-matrix  Skip the full shell matrix and run only the management harnesses.
  --management-only    Alias for --skip-shell-matrix.
EOF
        exit 0
        ;;
      *)
        printf 'Unknown argument: %s\n' "$1" >&2
        exit 2
        ;;
    esac
  done

  if (( run_shell_matrix == 1 )); then
    run_shell_case 'top + left with right dock' '{
      "dock": {"enabled": true, "position": "right"},
      "bars": {
        "configs": [
          {"id":"bar-top","name":"Top","enabled":true,"position":"top","displayMode":"all"},
          {"id":"bar-left","name":"Left","enabled":true,"position":"left","displayMode":"primary"}
        ]
      }
    }'

    run_shell_case 'bottom + right with left dock' '{
      "dock": {"enabled": true, "position": "left"},
      "bars": {
        "configs": [
          {"id":"bar-bottom","name":"Bottom","enabled":true,"position":"bottom","displayMode":"all"},
          {"id":"bar-right","name":"Right","enabled":true,"position":"right","displayMode":"primary"}
        ]
      }
    }'

    run_shell_case 'shared-edge left dock yield' '{
      "dock": {"enabled": true, "position": "left"},
      "bars": {
        "configs": [
          {"id":"bar-left","name":"Left","enabled":true,"position":"left","displayMode":"all"},
          {"id":"bar-bottom","name":"Bottom","enabled":true,"position":"bottom","displayMode":"all"}
        ]
      }
    }'

    run_shell_case 'top + bottom + left with right dock' '{
      "dock": {"enabled": true, "position": "right"},
      "bars": {
        "configs": [
          {"id":"bar-top","name":"Top","enabled":true,"position":"top","displayMode":"all"},
          {"id":"bar-bottom","name":"Bottom","enabled":true,"position":"bottom","displayMode":"all"},
          {"id":"bar-left","name":"Left","enabled":true,"position":"left","displayMode":"primary"}
        ]
      }
    }'
  fi

  run_management_harnesses

  printf '[INFO] Summary: %d pass, %d warn, %d skip, %d fail\n' "${pass_count}" "${warn_count}" "${skip_count}" "${fail_count}"
  (( fail_count == 0 ))
}

main "$@"
