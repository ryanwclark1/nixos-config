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

    snapshot("updates", updatesWidget, panel);
    snapshot("ssh", sshWidget, panel);
    snapshot("keyboardLayout", keyboardWidget, panel);

    console.log("RESULT:" + JSON.stringify(results));
    updatesWidget.destroy();
    sshWidget.destroy();
    keyboardWidget.destroy();
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

printf '%s\n' "${output}"

if [[ ${status} -ne 0 && ${status} -ne 124 ]]; then
  printf '[FAIL] collapse harness exited with status %s.\n' "${status}" >&2
  exit 1
fi

grep -q 'RESULT:' <<<"${output}" || {
  printf '[FAIL] collapse harness did not emit a RESULT payload.\n' >&2
  exit 1
}

grep -q '"updates":{"visible":false,"implicitWidth":0,"implicitHeight":0,"occupiesSpace":false}' <<<"${output}" || {
  printf '[FAIL] hidden updates widget still reports layout footprint.\n' >&2
  exit 1
}

grep -q '"ssh":{"visible":false,"implicitWidth":0,"implicitHeight":0,"occupiesSpace":false}' <<<"${output}" || {
  printf '[FAIL] hidden SSH widget still reports layout footprint.\n' >&2
  exit 1
}

grep -q '"keyboardLayout":{"visible":false,' <<<"${output}" || {
  printf '[FAIL] keyboard layout widget did not collapse in the offscreen harness.\n' >&2
  exit 1
}

grep -q '"keyboardLayout":{[^}]*"occupiesSpace":false' <<<"${output}" || {
  printf '[FAIL] hidden keyboard layout widget still reports layout occupancy.\n' >&2
  exit 1
}

printf '[PASS] hidden bar widgets collapse to zero layout footprint.\n'
