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
    "selectedBarId": "bar-secondary",
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
      },
      {
        "id": "bar-secondary",
        "name": "Secondary",
        "enabled": true,
        "position": "bottom",
        "sectionWidgets": {
          "left": [
            {
              "instanceId": "cpu-left-1",
              "widgetType": "cpuStatus",
              "enabled": true,
              "settings": {
                "displayMode": "compact"
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
import "./src/services"
import "./src/features/settings/components/tabs"

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
    if (node.widgetSettingsOpen !== undefined)
      results.barWidgetsTab = node;
    if (node.formPort !== undefined && !results.sshSettingsNode)
      results.sshSettingsNode = node;
    var children = node.children || [];
    for (var i = 0; i < children.length; ++i)
      scan(children[i], results);
  }

  QtObject {
    id: fakeSettingsRoot
    property var pendingBarWidgetTarget: null
  }

  BarWidgetsTab {
    id: tab
    width: 960
    height: 760
    tabId: "bar-widgets"
    compactMode: true
    tightSpacing: false
    settingsRoot: fakeSettingsRoot
  }

  Component.onCompleted: {
    Config.load();
    fakeSettingsRoot.pendingBarWidgetTarget = Config.findBarWidgetInstance("ssh-left-1");
    Qt.callLater(function() {
      tab.applyPendingBarWidgetTarget();
      Qt.callLater(function() {
        tab.applyPendingBarWidgetTarget();
        Qt.callLater(function() {
          var scanResults = {
            sshSettingsNodes: 0,
            manualSearchNodes: 0,
            sshBoundNodes: 0,
            barWidgetsTab: null,
            sshSettingsNode: null
          };
          scan(tab, scanResults);
          var barWidgetsTab = scanResults.barWidgetsTab;
          var sshSettings = scanResults.sshSettingsNode;
          var invalidSaveError = "";
          var invalidSaveHostCount = -1;
          var cancelState = null;
          if (sshSettings) {
            sshSettings.formLabel = "";
            sshSettings.formHost = "";
            sshSettings.formPort = "not-a-port";
            sshSettings.saveHost();
            invalidSaveError = String(sshSettings.formError || "");
            var invalidWidget = Config.widgetInstance("bar-primary", "left", "ssh-left-1");
            var invalidHosts = invalidWidget && invalidWidget.settings && Array.isArray(invalidWidget.settings.manualHosts)
              ? invalidWidget.settings.manualHosts
              : [];
            invalidSaveHostCount = invalidHosts.length;

            sshSettings.editHostAt(0);
            sshSettings.formLabel = "Prod Draft";
            sshSettings.formPort = "2200";
            sshSettings.resetForm();
            cancelState = {
              editingHostId: String(sshSettings.editingHostId || ""),
              formLabel: String(sshSettings.formLabel || ""),
              formPort: String(sshSettings.formPort || ""),
              formError: String(sshSettings.formError || "")
            };

            sshSettings.formLabel = "Staging";
            sshSettings.formHost = "staging.internal";
            sshSettings.formUser = "deploy";
            sshSettings.formPort = "2222";
            sshSettings.formTags = "qa, edge";
            sshSettings.formGroup = "qa";
            sshSettings.saveHost();
          }
          var widget = Config.widgetInstance("bar-primary", "left", "ssh-left-1");
          var manualHosts = widget && widget.settings && Array.isArray(widget.settings.manualHosts)
            ? widget.settings.manualHosts
            : [];
          var results = {
            selectedBarId: String(Config.selectedBarId || ""),
            editingWidgetType: barWidgetsTab && barWidgetsTab.editingWidget ? String(barWidgetsTab.editingWidget.widgetType || "") : "",
            editingSchemaLength: barWidgetsTab && barWidgetsTab.editingWidgetSchema ? barWidgetsTab.editingWidgetSchema.length : -1,
            widgetSettingsOpen: barWidgetsTab ? barWidgetsTab.widgetSettingsOpen : false,
            settingsInstanceId: barWidgetsTab ? barWidgetsTab.settingsInstanceId : "",
            sshSettingsNodes: scanResults.sshSettingsNodes,
            manualSearchNodes: scanResults.manualSearchNodes,
            sshBoundNodes: scanResults.sshBoundNodes,
            invalidSaveError: invalidSaveError,
            invalidSaveHostCount: invalidSaveHostCount,
            cancelState: cancelState,
            manualHostCount: manualHosts.length,
            savedHost: manualHosts.length > 1 ? {
              label: String(manualHosts[1].label || ""),
              host: String(manualHosts[1].host || ""),
              user: String(manualHosts[1].user || ""),
              port: Number(manualHosts[1].port || 0),
              group: String(manualHosts[1].group || ""),
              tags: Array.isArray(manualHosts[1].tags) ? manualHosts[1].tags : []
            } : null
          };
          console.log("RESULT:" + JSON.stringify(results));
          Qt.quit();
        });
      });
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

if results.get("selectedBarId") != "bar-primary":
    print("[FAIL] SSH settings smoke did not switch to the target bar.", file=sys.stderr)
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

if results.get("invalidSaveError") != "Label and host are required.":
    print("[FAIL] SSH settings smoke did not surface the expected validation error.", file=sys.stderr)
    sys.exit(1)

if results.get("invalidSaveHostCount") != 1:
    print("[FAIL] SSH settings smoke mutated manual hosts on invalid save.", file=sys.stderr)
    sys.exit(1)

cancel_state = results.get("cancelState") or {}
if cancel_state.get("editingHostId") != "" or cancel_state.get("formLabel") != "" or cancel_state.get("formError") != "":
    print("[FAIL] SSH settings smoke did not clear draft state on cancel/reset.", file=sys.stderr)
    sys.exit(1)

if cancel_state.get("formPort") != "22":
    print("[FAIL] SSH settings smoke did not restore the default port on cancel/reset.", file=sys.stderr)
    sys.exit(1)

saved = results.get("savedHost") or {}
if results.get("manualHostCount") != 2:
    print("[FAIL] SSH settings smoke did not persist the new manual host.", file=sys.stderr)
    sys.exit(1)

if saved.get("label") != "Staging" or saved.get("host") != "staging.internal" or saved.get("user") != "deploy":
    print("[FAIL] SSH settings smoke saved the wrong host fields.", file=sys.stderr)
    sys.exit(1)

if saved.get("port") != 2222 or saved.get("group") != "qa" or saved.get("tags") != ["qa", "edge"]:
    print("[FAIL] SSH settings smoke did not normalize saved SSH host metadata as expected.", file=sys.stderr)
    sys.exit(1)
PY

printf '[PASS] SSH widget settings smoke deep-linked and saved through the custom editor.\n'
