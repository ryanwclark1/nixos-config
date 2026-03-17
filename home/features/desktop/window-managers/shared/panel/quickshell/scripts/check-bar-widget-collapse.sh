#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." >/dev/null 2>&1 && pwd -P)"

tmp_home="$(mktemp -d)"
tmp_runtime="$(mktemp -d)"
tmp_qml="$(mktemp "${repo_root}/tmp-bar-widget-collapse-XXXXXX.qml")"

cleanup() {
  rm -rf -- "${tmp_home}" "${tmp_runtime}"
  rm -f -- "${tmp_qml}"
}
trap cleanup EXIT

mkdir -p "${tmp_home}/.local/state/quickshell" "${tmp_home}/.config/quickshell" "${tmp_runtime}/quickshell"
chmod 700 "${tmp_runtime}"
printf '{"themes":[]}\n' > "${tmp_home}/.config/quickshell/themes.json"

cat > "${tmp_qml}" <<'QML'
import Quickshell
import QtQuick
import "./config/services"
import "./config/bar" as Bar

Scope {
  id: root

  property var results: ({})

  function snapshot(name, item, panel) {
    results[name] = {
      visible: item ? item.visible : null,
      implicitWidth: item ? Number(item.implicitWidth || 0) : -1,
      implicitHeight: item ? Number(item.implicitHeight || 0) : -1,
      occupiesSpace: item ? panel.itemOccupiesSpace(item) : null
    };
  }

  Bar.Panel {
    id: panel
    barConfig: ({
      id: "test-bar",
      position: "top",
      sectionWidgets: { left: [], center: [], right: [] }
    })

    Item {
      id: harnessHost
      anchors.fill: parent
      visible: false
    }
  }

  Component.onCompleted: {
    var updatesWidget = panel.componentForWidget("updates").createObject(harnessHost, {
      widgetInstance: { instanceId: "updates-test", widgetType: "updates", enabled: true, settings: { displayMode: "auto" } }
    });
    var sshWidget = panel.componentForWidget("ssh").createObject(harnessHost, {
      widgetInstance: {
        instanceId: "ssh-test",
        widgetType: "ssh",
        enabled: true,
        settings: {
          manualHosts: [],
          enableSshConfigImport: false
        }
      }
    });
    var keyboardWidget = panel.componentForWidget("keyboardLayout").createObject(harnessHost, {
      widgetInstance: { instanceId: "kbd-test", widgetType: "keyboardLayout", enabled: true, settings: { labelMode: "short" } }
    });
    var musicWidget = panel.componentForWidget("music").createObject(harnessHost, {
      widgetInstance: { instanceId: "music-test", widgetType: "music", enabled: true, settings: { displayMode: "auto" } }
    });
    var privacyWidget = panel.componentForWidget("privacy").createObject(harnessHost, {
      widgetInstance: { instanceId: "privacy-test", widgetType: "privacy", enabled: true, settings: { displayMode: "auto" } }
    });
    var recordingWidget = panel.componentForWidget("recording").createObject(harnessHost, {
      widgetInstance: { instanceId: "recording-test", widgetType: "recording", enabled: true, settings: { displayMode: "auto" } }
    });
    var printerWidget = panel.componentForWidget("printer").createObject(harnessHost, {
      widgetInstance: { instanceId: "printer-test", widgetType: "printer", enabled: true, settings: { displayMode: "auto" } }
    });
    var batteryWidget = panel.componentForWidget("battery").createObject(harnessHost, {
      widgetInstance: { instanceId: "battery-test", widgetType: "battery", enabled: true, settings: { displayMode: "auto" } }
    });

    snapshot("updates", updatesWidget, panel);
    snapshot("ssh", sshWidget, panel);
    snapshot("keyboardLayout", keyboardWidget, panel);
    snapshot("music", musicWidget, panel);
    snapshot("privacy", privacyWidget, panel);
    snapshot("recording", recordingWidget, panel);
    snapshot("printer", printerWidget, panel);
    snapshot("battery", batteryWidget, panel);

    console.log("RESULT:" + JSON.stringify(results));
    updatesWidget.destroy();
    sshWidget.destroy();
    keyboardWidget.destroy();
    musicWidget.destroy();
    privacyWidget.destroy();
    recordingWidget.destroy();
    printerWidget.destroy();
    batteryWidget.destroy();
    Qt.quit();
  }
}
QML

set +e
output="$(
  env -u WAYLAND_DISPLAY -u DISPLAY \
    HOME="${tmp_home}" \
    XDG_RUNTIME_DIR="${tmp_runtime}" \
    QT_QPA_PLATFORM=offscreen \
    timeout 10s quickshell -p "${tmp_qml}" --no-duplicate 2>&1
)"
status=$?
set -e

filtered_output="$(
  printf '%s\n' "${output}" | grep -Ev \
    '^(No running instances for |  WARN: Unable to find hyprland socket\. Cannot connect to hyprland\.|  WARN quickshell\.hyprland\.ipc: Error making request: QLocalSocket::ServerNotFoundError request: "j/clients"|  WARN: Signal QQmlEngine::quit\(\) emitted, but no receivers connected to handle it\.|  WARN quickshell\.io\.fileview: got operation finished from dropped operation .*|  INFO: Reloading configuration\.\.\.|  WARN: QQmlComponent: Component is not ready| ERROR: Failed to open reload popup: )'
)"

if [[ -n "${filtered_output}" ]]; then
  printf '%s\n' "${filtered_output}"
fi

if [[ ${status} -ne 0 && ${status} -ne 124 ]]; then
  printf '[FAIL] collapse harness exited with status %s.\n' "${status}" >&2
  exit 1
fi

grep -q 'RESULT:' <<<"${output}" || {
  printf '[FAIL] collapse harness did not emit a RESULT payload.\n' >&2
  exit 1
}

result_line="$(printf '%s\n' "${output}" | sed -n 's/^.*RESULT://p' | tail -n 1)"

python - "${result_line}" <<'PY'
import json
import sys

results = json.loads(sys.argv[1])

required_hidden = {
    "updates": "hidden updates widget still reports layout footprint.",
    "ssh": "hidden SSH widget still reports layout footprint.",
    "keyboardLayout": "hidden keyboard layout widget still reports layout footprint.",
}

for key, message in required_hidden.items():
    entry = results.get(key)
    if not entry or entry.get("visible") is not False or entry.get("occupiesSpace") is not False:
        print(f"[FAIL] {message}", file=sys.stderr)
        sys.exit(1)

optional_hidden = {
    "battery": "hidden battery widget still reports layout footprint.",
    "music": "hidden music widget still reports layout footprint.",
    "privacy": "hidden privacy widget still reports layout footprint.",
    "recording": "hidden recording widget still reports layout footprint.",
    "printer": "hidden printer widget still reports layout footprint.",
}

for key, message in optional_hidden.items():
    entry = results.get(key)
    if entry and entry.get("visible") is False and entry.get("occupiesSpace") is not False:
        print(f"[FAIL] {message}", file=sys.stderr)
        sys.exit(1)
PY

printf '[PASS] hidden bar widgets collapse to zero layout footprint.\n'
