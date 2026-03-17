#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." >/dev/null 2>&1 && pwd -P)"

tmp_home="$(mktemp -d)"
tmp_runtime="$(mktemp -d)"
tmp_qml="$(mktemp "${repo_root}/tmp-ssh-settings-smoke-XXXXXX.qml")"

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
    "selectedBarId": "bar-primary",
    "configs": [
      {
        "id": "bar-primary",
        "name": "Primary",
        "enabled": true,
        "position": "top",
        "sectionWidgets": {
          "left": [
            {
              "instanceId": "ssh-left-1",
              "widgetType": "ssh",
              "enabled": true,
              "settings": {
                "manualHosts": [
                  {
                    "id": "prod",
                    "label": "Prod",
                    "host": "prod.example.com",
                    "user": "root",
                    "port": 22,
                    "tags": ["ops"],
                    "group": "ops"
                  }
                ],
                "enableSshConfigImport": false,
                "displayMode": "recent"
              }
            }
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
import "./config/services"
import "./config/menu/settings/tabs"

Scope {
  id: root

  function scan(node, results) {
    if (!node)
      return;
    if (node.formPort !== undefined)
      results.sshSettingsNodes += 1;
    if (node.manualSearchQuery !== undefined)
      results.manualSearchNodes += 1;
    if (node.widgetInstance !== undefined && node.widgetInstance && String(node.widgetInstance.widgetType || "") === "ssh")
      results.sshBoundNodes += 1;
    var children = node.children || [];
    for (var i = 0; i < children.length; ++i)
      scan(children[i], results);
  }

  BarWidgetsTab {
    id: tab
    width: 960
    height: 760
    tabId: "bar-widgets"
    compactMode: true
    tightSpacing: false
  }

  Component.onCompleted: {
    Config.load();
    tab.openWidgetSettings("left", "ssh-left-1");
    Qt.callLater(function() {
      var results = {
        editingWidgetType: tab.editingWidget ? String(tab.editingWidget.widgetType || "") : "",
        editingSchemaLength: tab.editingWidgetSchema ? tab.editingWidgetSchema.length : -1,
        widgetSettingsOpen: tab.widgetSettingsOpen,
        settingsInstanceId: tab.settingsInstanceId,
        sshSettingsNodes: 0,
        manualSearchNodes: 0,
        sshBoundNodes: 0
      };
      scan(tab, results);
      console.log("RESULT:" + JSON.stringify(results));
      Qt.quit();
    });
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
exit_code=$?
set -e

filtered_output="$(
  printf '%s\n' "${output}" | grep -Ev \
    '^(No running instances for |  WARN: Unable to find hyprland socket\. Cannot connect to hyprland\.|  WARN quickshell\.hyprland\.ipc: Error making request: QLocalSocket::ServerNotFoundError request: "j/clients"|  WARN: Signal QQmlEngine::quit\(\) emitted, but no receivers connected to handle it\.|  WARN quickshell\.io\.fileview: got operation finished from dropped operation .*|  INFO: Reloading configuration\.\.\.| ERROR: Failed to open reload popup: )'
)"

if [[ -n "${filtered_output}" ]]; then
  printf '%s\n' "${filtered_output}"
fi

if [[ ${exit_code} -ne 0 && ${exit_code} -ne 124 ]]; then
  printf '[FAIL] SSH settings smoke exited with status %s.\n' "${exit_code}" >&2
  exit 1
fi

grep -q 'RESULT:' <<<"${output}" || {
  printf '[FAIL] SSH settings smoke did not emit a RESULT payload.\n' >&2
  exit 1
}

result_line="$(printf '%s\n' "${output}" | sed -n 's/^.*RESULT://p' | tail -n 1)"

python - "${result_line}" <<'PY'
import json
import sys

results = json.loads(sys.argv[1])

if results.get("editingWidgetType") != "ssh":
    print("[FAIL] SSH settings smoke did not target the SSH widget.", file=sys.stderr)
    sys.exit(1)

if results.get("widgetSettingsOpen") is not True:
    print("[FAIL] SSH widget settings modal did not open.", file=sys.stderr)
    sys.exit(1)

if results.get("settingsInstanceId") != "ssh-left-1":
    print("[FAIL] SSH widget settings targeted the wrong instance.", file=sys.stderr)
    sys.exit(1)

if results.get("sshSettingsNodes", 0) < 1 or results.get("manualSearchNodes", 0) < 1:
    print("[FAIL] SSH settings pane did not instantiate its custom editor.", file=sys.stderr)
    sys.exit(1)
PY

printf '[PASS] SSH widget settings smoke loaded the custom editor.\n'
