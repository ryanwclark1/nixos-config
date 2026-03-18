#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
config_dir="${QS_CONFIG_DIR:-${script_dir}/../src}"
repo_root="$(cd -- "${script_dir}/.." >/dev/null 2>&1 && pwd -P)"
source "${script_dir}/harness-warnings.sh"

tmp_home="$(mktemp -d)"
tmp_runtime="$(mktemp -d)"
tmp_qml="$(mktemp "${repo_root}/tmp-widget-picker-search-harness-XXXXXX.qml")"

cleanup() {
  rm -rf -- "${tmp_home}" "${tmp_runtime}"
  rm -f -- "${tmp_qml}"
}
trap cleanup EXIT

mkdir -p "${tmp_home}/.local/state/quickshell" "${tmp_home}/.config/quickshell" "${tmp_runtime}/quickshell"
chmod 700 "${tmp_runtime}"
printf '{"themes":[]}\n' > "${tmp_home}/.config/quickshell/themes.json"
mkdir -p "${tmp_home}/.config/quickshell/plugins/test-bar"

cat > "${tmp_home}/.config/quickshell/plugins/test-bar/manifest.json" <<'JSON'
{
  "id": "test-bar",
  "name": "Test Bar Plugin",
  "description": "Temporary widget picker harness plugin.",
  "author": "Codex",
  "version": "1.0.0",
  "type": "bar-widget",
  "permissions": [],
  "entryPoints": {
    "barWidget": "BarWidget.qml"
  }
}
JSON

cat > "${tmp_home}/.config/quickshell/plugins/test-bar/BarWidget.qml" <<'QML'
import QtQuick

Item {}
QML

cat > "${tmp_home}/.local/state/quickshell/config.json" <<'JSON'
{
  "desktopWidgetsEnabled": true,
  "desktopWidgetsGridSnap": false,
  "desktopWidgetsMonitorWidgets": [],
  "bars": {
    "selectedBarId": "bar-main",
    "configs": [
      {
        "id": "bar-main",
        "name": "Main Bar",
        "enabled": true,
        "position": "top",
        "displayMode": "all",
        "height": 38,
        "floating": true,
        "margin": 12,
        "opacity": 0.85,
        "sectionWidgets": {
          "left": [
            { "instanceId": "logo-1", "widgetType": "logo", "enabled": true, "settings": {} }
          ],
          "center": [],
          "right": []
        }
      }
    ]
  }
}
JSON

cat > "${tmp_qml}" <<'QML'
import Quickshell
import QtQuick
import QtQuick.Layouts
import "./src/services"
import "./src/widgets"
import "./src/features/settings/components/tabs"

Item {
  width: 960
  height: 760

  function widgetTypes(items) {
    var result = [];
    for (var i = 0; i < items.length; ++i)
      result.push(String(items[i].widgetType || items[i].id || ""));
    return result;
  }

  function hasValue(items, value) {
    for (var i = 0; i < items.length; ++i) {
      if (String(items[i]) === value)
        return true;
    }
    return false;
  }

  BarWidgetsTab {
    id: barPicker
    anchors.fill: parent
    tabId: "bar-widgets"
    compactMode: true
    addSection: "left"
    widgetPickerOpen: true
  }

  DesktopWidgets {
    id: desktopPicker
    anchors.fill: parent
    widgetPickerOpen: true
  }

  Timer {
    interval: 50
    running: true
    repeat: true
    property int attempts: 0

    onTriggered: {
      attempts += 1;
      if (Config._loading && attempts < 40)
        return;

      stop();

      barPicker.widgetSearchQuery = "";
      var barAllTypes = widgetTypes(barPicker.availableWidgetsForPicker());
      console.log("BAR_ALL_COUNT", barAllTypes.length);
      console.log("BAR_HAS_BATTERY", hasValue(barAllTypes, "battery"));
      console.log("BAR_HAS_PRINTER", hasValue(barAllTypes, "printer"));
      console.log("BAR_HAS_SYSTEM_MONITOR", hasValue(barAllTypes, "systemMonitor"));
      console.log("BAR_HAS_PLUGIN_TEST", hasValue(barAllTypes, "plugin:test-bar"));

      barPicker.widgetSearchQuery = "print";
      var barPrintTypes = widgetTypes(barPicker.availableWidgetsForPicker());
      console.log("BAR_PRINT_COUNT", barPrintTypes.length);
      console.log("BAR_PRINT_TYPES", barPrintTypes.join(","));

      desktopPicker.widgetSearchQuery = "";
      var desktopAllTypes = widgetTypes(desktopPicker.availableDesktopWidgets);
      console.log("DESKTOP_ALL_COUNT", desktopAllTypes.length);
      console.log("DESKTOP_HAS_CLOCK", hasValue(desktopAllTypes, "Clock"));
      console.log("DESKTOP_HAS_WEATHER", hasValue(desktopAllTypes, "Weather"));

      desktopPicker.widgetSearchQuery = "weather";
      var desktopWeatherTypes = widgetTypes(desktopPicker.availableDesktopWidgets);
      console.log("DESKTOP_WEATHER_COUNT", desktopWeatherTypes.length);
      console.log("DESKTOP_WEATHER_TYPES", desktopWeatherTypes.join(","));

      Qt.quit();
    }
  }
}
QML

set +e
output="$(
  env -u WAYLAND_DISPLAY -u DISPLAY \
    HOME="${tmp_home}" \
    XDG_RUNTIME_DIR="${tmp_runtime}" \
    QT_QPA_PLATFORM=offscreen \
    timeout 5s quickshell -p "${tmp_qml}" --no-duplicate 2>&1
)"
status=$?
set -e

filtered_output="$(filter_known_quickshell_harness_warnings "${output}")"

if [[ -n "${filtered_output}" ]]; then
  printf '%s\n' "${filtered_output}"
fi

if [[ ${status} -ne 0 && ${status} -ne 124 ]]; then
  printf '[FAIL] quickshell harness exited with status %s.\n' "${status}" >&2
  exit 1
fi

fail_on_quickshell_harness_warnings "Widget picker harness" "${output}" "${filtered_output}"

grep -q 'BAR_HAS_BATTERY true' <<<"${output}" || {
  printf '[FAIL] Bar widget picker did not expose right-section widgets when adding to left.\n' >&2
  exit 1
}

grep -q 'BAR_HAS_PRINTER true' <<<"${output}" || {
  printf '[FAIL] Bar widget picker did not expose the full widget catalog.\n' >&2
  exit 1
}

grep -q 'BAR_HAS_SYSTEM_MONITOR true' <<<"${output}" || {
  printf '[FAIL] Bar widget picker did not expose the legacy internal system monitor widget.\n' >&2
  exit 1
}

grep -q 'BAR_HAS_PLUGIN_TEST true' <<<"${output}" || {
  printf '[FAIL] Bar widget picker did not expose enabled plugin widgets.\n' >&2
  exit 1
}

grep -q 'BAR_PRINT_COUNT 1' <<<"${output}" || {
  printf '[FAIL] Bar widget search did not narrow to the expected printer widget.\n' >&2
  exit 1
}

grep -q 'BAR_PRINT_TYPES printer' <<<"${output}" || {
  printf '[FAIL] Bar widget search returned the wrong widget types for "print".\n' >&2
  exit 1
}

grep -q 'DESKTOP_HAS_CLOCK true' <<<"${output}" || {
  printf '[FAIL] Desktop widget picker did not expose the built-in widget catalog.\n' >&2
  exit 1
}

grep -q 'DESKTOP_HAS_WEATHER true' <<<"${output}" || {
  printf '[FAIL] Desktop widget picker did not expose all built-in widgets.\n' >&2
  exit 1
}

grep -q 'DESKTOP_WEATHER_COUNT 1' <<<"${output}" || {
  printf '[FAIL] Desktop widget search did not narrow to Weather.\n' >&2
  exit 1
}

grep -q 'DESKTOP_WEATHER_TYPES Weather' <<<"${output}" || {
  printf '[FAIL] Desktop widget search returned the wrong widget identifiers.\n' >&2
  exit 1
}

printf '[PASS] Widget add pickers expose full catalogs and searchable results.\n'
