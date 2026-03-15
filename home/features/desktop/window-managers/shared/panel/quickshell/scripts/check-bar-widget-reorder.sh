#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
config_dir="${script_dir}/../config"

tmp_home="$(mktemp -d)"
tmp_runtime="$(mktemp -d)"
tmp_dir="$(mktemp -d)"
tmp_qml="${tmp_dir}/reorder-harness.qml"
cleanup() {
  rm -rf -- "${tmp_home}" "${tmp_runtime}" "${tmp_dir}"
}
trap cleanup EXIT

mkdir -p "${tmp_home}/.local/state/quickshell" "${tmp_home}/.config/quickshell" "${tmp_runtime}/quickshell"
chmod 700 "${tmp_runtime}"
printf '{"themes":[]}\n' > "${tmp_home}/.config/quickshell/themes.json"
ln -s "${config_dir}/services" "${tmp_dir}/services"
ln -s "${config_dir}/widgets" "${tmp_dir}/widgets"

cat > "${tmp_home}/.local/state/quickshell/config.json" <<'JSON'
{
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
            { "instanceId": "logo-1", "widgetType": "logo", "enabled": true, "settings": {} },
            { "instanceId": "workspaces-1", "widgetType": "workspaces", "enabled": true, "settings": {} },
            { "instanceId": "window-title-1", "widgetType": "windowTitle", "enabled": true, "settings": {} }
          ],
          "center": [],
          "right": []
        }
      }
    ]
  }
}
JSON

cat > "${tmp_qml}" <<QML
import Quickshell
import QtQuick
import "./services"

QtObject {
  property int attempts: 0

  function leftOrder() {
    var bar = Config.barById("bar-main");
    var widgets = Config.barSectionWidgets(bar, "left");
    var ids = [];
    for (var i = 0; i < widgets.length; ++i)
      ids.push(String(widgets[i].instanceId || ""));
    return ids.join(",");
  }

  function runChecks() {
    console.log("INITIAL", leftOrder());

    var movedToEnd = Config.moveBarWidget("bar-main", "left", 0, 3, "left");
    console.log("MOVE_END_OK", movedToEnd);
    console.log("MOVE_END_ORDER", leftOrder());

    var movedUp = Config.moveBarWidget("bar-main", "left", 2, 0, "left");
    console.log("MOVE_UP_OK", movedUp);
    console.log("MOVE_UP_ORDER", leftOrder());

    Qt.quit();
  }

  property Timer loadTimer: Timer {
    interval: 50
    running: true
    repeat: true
    onTriggered: {
      attempts += 1;
      if ((Config.barConfigs || []).length > 0 && !Config._loading) {
        stop();
        runChecks();
        return;
      }
      if (attempts > 40) {
        console.log("LOAD_TIMEOUT", (Config.barConfigs || []).length, Config._loading);
        stop();
        Qt.quit();
      }
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

printf '%s\n' "${output}"

if [[ ${status} -ne 0 && ${status} -ne 124 ]]; then
  printf '[FAIL] quickshell harness exited with status %s.\n' "${status}" >&2
  exit 1
fi

grep -q 'MOVE_END_OK true' <<<"${output}" || {
  printf '[FAIL] moveBarWidget rejected same-section end drop.\n' >&2
  exit 1
}

grep -q 'MOVE_END_ORDER workspaces-1,window-title-1,logo-1' <<<"${output}" || {
  printf '[FAIL] moveBarWidget produced the wrong order for same-section end drop.\n' >&2
  exit 1
}

grep -q 'MOVE_UP_OK true' <<<"${output}" || {
  printf '[FAIL] moveBarWidget rejected upward same-section reorder.\n' >&2
  exit 1
}

grep -q 'MOVE_UP_ORDER logo-1,workspaces-1,window-title-1' <<<"${output}" || {
  printf '[FAIL] moveBarWidget produced the wrong order for upward same-section reorder.\n' >&2
  exit 1
}

printf '[PASS] moveBarWidget preserves expected same-section reorder semantics.\n'
