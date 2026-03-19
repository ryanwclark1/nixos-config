#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
config_dir="${QS_CONFIG_DIR:-${script_dir}/../src}"
repo_root="$(cd -- "${script_dir}/.." >/dev/null 2>&1 && pwd -P)"
source "${script_dir}/harness-warnings.sh"

tmp_home="$(mktemp -d)"
tmp_runtime="$(mktemp -d)"
tmp_qml="$(mktemp "${repo_root}/tmp-reorder-harness-XXXXXX.qml")"
cleanup() {
  rm -rf -- "${tmp_home}" "${tmp_runtime}"
  rm -f -- "${tmp_qml}"
}
trap cleanup EXIT

mkdir -p "${tmp_home}/.local/state/quickshell" "${tmp_home}/.config/quickshell" "${tmp_runtime}/quickshell"
chmod 700 "${tmp_runtime}"
printf '{"themes":[]}\n' > "${tmp_home}/.config/quickshell/themes.json"

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
          "center": [
            { "instanceId": "clock-1", "widgetType": "clock", "enabled": true, "settings": {} }
          ],
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
import "./src/services"

QtObject {
  property int attempts: 0

  function leftOrder() {
    return sectionOrder("left");
  }

  function centerOrder() {
    return sectionOrder("center");
  }

  function rightOrder() {
    return sectionOrder("right");
  }

  function sectionOrder(section) {
    var bar = Config.barById("bar-main");
    var widgets = Config.barSectionWidgets(bar, section);
    var ids = [];
    for (var i = 0; i < widgets.length; ++i)
      ids.push(String(widgets[i].instanceId || ""));
    return ids.length > 0 ? ids.join(",") : "<empty>";
  }

  function runChecks() {
    console.log("INITIAL", leftOrder());
    console.log("INITIAL_CENTER", centerOrder());
    console.log("INITIAL_RIGHT", rightOrder());

    var movedToEnd = Config.moveBarWidget("bar-main", "left", 0, 3, "left");
    console.log("MOVE_END_OK", movedToEnd);
    console.log("MOVE_END_ORDER", leftOrder());

    var movedUp = Config.moveBarWidget("bar-main", "left", 2, 0, "left");
    console.log("MOVE_UP_OK", movedUp);
    console.log("MOVE_UP_ORDER", leftOrder());

    var movedToCenter = Config.moveBarWidget("bar-main", "left", 1, 1, "center");
    console.log("MOVE_CENTER_OK", movedToCenter);
    console.log("MOVE_CENTER_LEFT", leftOrder());
    console.log("MOVE_CENTER_CENTER", centerOrder());

    var movedToEmptyRight = Config.moveBarWidget("bar-main", "left", 0, 0, "right");
    console.log("MOVE_EMPTY_RIGHT_OK", movedToEmptyRight);
    console.log("MOVE_EMPTY_RIGHT_LEFT", leftOrder());
    console.log("MOVE_EMPTY_RIGHT_RIGHT", rightOrder());

    var movedToCenterEnd = Config.moveBarWidget("bar-main", "right", 0, 2, "center");
    console.log("MOVE_CENTER_END_OK", movedToCenterEnd);
    console.log("MOVE_CENTER_END_CENTER", centerOrder());
    console.log("MOVE_CENTER_END_RIGHT", rightOrder());

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
    QS_SCRIPT_ROOT="${repo_root}/scripts" \
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

fail_on_quickshell_harness_warnings "Reorder harness" "${output}" "${filtered_output}"

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

grep -q 'MOVE_CENTER_OK true' <<<"${output}" || {
  printf '[FAIL] moveBarWidget rejected cross-section move into populated section.\n' >&2
  exit 1
}

grep -q 'MOVE_CENTER_LEFT logo-1,window-title-1' <<<"${output}" || {
  printf '[FAIL] moveBarWidget produced the wrong source order after populated cross-section move.\n' >&2
  exit 1
}

grep -q 'MOVE_CENTER_CENTER clock-1,workspaces-1' <<<"${output}" || {
  printf '[FAIL] moveBarWidget produced the wrong target order for populated cross-section move.\n' >&2
  exit 1
}

grep -q 'MOVE_EMPTY_RIGHT_OK true' <<<"${output}" || {
  printf '[FAIL] moveBarWidget rejected move into empty section.\n' >&2
  exit 1
}

grep -q 'MOVE_EMPTY_RIGHT_LEFT window-title-1' <<<"${output}" || {
  printf '[FAIL] moveBarWidget produced the wrong source order after empty-section move.\n' >&2
  exit 1
}

grep -q 'MOVE_EMPTY_RIGHT_RIGHT logo-1' <<<"${output}" || {
  printf '[FAIL] moveBarWidget produced the wrong target order for empty-section move.\n' >&2
  exit 1
}

grep -q 'MOVE_CENTER_END_OK true' <<<"${output}" || {
  printf '[FAIL] moveBarWidget rejected end-of-section cross-section move.\n' >&2
  exit 1
}

grep -q 'MOVE_CENTER_END_CENTER clock-1,workspaces-1,logo-1' <<<"${output}" || {
  printf '[FAIL] moveBarWidget produced the wrong order for end-of-section cross-section move.\n' >&2
  exit 1
}

grep -q 'MOVE_CENTER_END_RIGHT <empty>' <<<"${output}" || {
  printf '[FAIL] moveBarWidget did not empty the source section after end-of-section move.\n' >&2
  exit 1
}

printf '[PASS] moveBarWidget preserves same-section and cross-section reorder semantics.\n'
