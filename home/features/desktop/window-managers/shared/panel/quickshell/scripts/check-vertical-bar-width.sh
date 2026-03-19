#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." >/dev/null 2>&1 && pwd -P)"

tmp_home="$(mktemp -d)"
tmp_runtime="$(mktemp -d)"
tmp_qml="$(mktemp "${repo_root}/tmp-vertical-bar-width-XXXXXX.qml")"

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
import QtQuick.Window
import "./src/services"
import "./src/bar" as Bar

Window {
  id: root
  visible: true
  color: "transparent"
  width: Math.max(1, panel.implicitWidth)
  height: 720

  property var results: ({})

  function walk(item, visitor) {
    if (!item)
      return false;
    var children = item.children || [];
    for (var i = 0; i < children.length; ++i) {
      var child = children[i];
      if (!child)
        continue;
      if (visitor(child))
        return true;
      if (walk(child, visitor))
        return true;
    }
    return false;
  }

  function wrapperFor(instanceId) {
    var found = null;
    walk(panel, function(child) {
      try {
        if (child.widgetInstance
            && child.widgetInstance.instanceId === instanceId
            && child.diagnosticState !== undefined) {
          found = child;
          return true;
        }
      } catch (e) {
      }
      return false;
    });
    return found;
  }

  function snapshot(name, instanceId) {
    var item = wrapperFor(instanceId);
    results[name] = {
      found: !!item,
      width: item ? Number(item.width || 0) : -1,
      height: item ? Number(item.height || 0) : -1,
      implicitWidth: item ? Number(item.implicitWidth || 0) : -1,
      implicitHeight: item ? Number(item.implicitHeight || 0) : -1,
      diagnosticState: item ? String(item.diagnosticState || "") : "",
      contributesLayout: item ? !!item.contributesLayout : null,
      occupiesSpace: item ? !!item.occupiesSpace : null,
      hiddenInVertical: item ? !!item.hiddenInVertical : null,
      collapseForVerticalOverflow: item ? !!item.collapseForVerticalOverflow : null,
      rawWidgetWidth: item ? Number(item.rawWidgetWidth || 0) : -1,
      rawWidgetHeight: item ? Number(item.rawWidgetHeight || 0) : -1,
      loaderHasItem: item ? !!(item.children && item.children.length > 0) : null,
      itemVisible: item && item.children && item.children.length > 0 ? item.children[0].visible : null,
      panelWidth: Number(panel.implicitWidth || 0),
      panelWidthCap: Number(panel.verticalBarWidthCap || 0),
      itemWidthCap: Number(panel.verticalItemWidthCap || 0)
    };
  }

  Component {
    id: wideDummyComponent
    Item {
      property var widgetInstance: null
      implicitWidth: 160
      implicitHeight: 20
      visible: true
    }
  }

  Bar.Panel {
    id: panel
    anchors.fill: parent
    barConfig: ({
      id: "vertical-test-bar",
      position: "left",
      sectionWidgets: { left: [], center: [], right: [] }
    })
  }

  Item {
    id: widgetProbeHost
    anchors.fill: parent
  }

  Timer {
    interval: 0
    repeat: false
    running: true
    onTriggered: {
      panel._widgetComponents["wideDummy"] = wideDummyComponent;
      panel.barConfig = {
        id: "vertical-test-bar",
        position: "left",
        sectionWidgets: {
          left: [
            { instanceId: "logo-full", widgetType: "logo", enabled: true, settings: { displayMode: "full", labelText: "Very Long Launcher Label" } },
            { instanceId: "title-full", widgetType: "windowTitle", enabled: true, settings: { maxTitleWidth: 480, showAppIcon: true, showGitStatus: true, showMediaContext: true } },
            { instanceId: "wide-dummy", widgetType: "wideDummy", enabled: true, settings: {} }
          ],
          center: [
            { instanceId: "clock-full", widgetType: "dateTime", enabled: true, settings: { displayMode: "full", showDate: true } },
            { instanceId: "cpu-full", widgetType: "cpuStatus", enabled: true, settings: { displayMode: "full", valueStyle: "usageTemp" } }
          ],
          right: [
            { instanceId: "ssh-vertical", widgetType: "ssh", enabled: true, settings: { manualHosts: [], enableSshConfigImport: false, showWhenEmpty: true, emptyLabel: "This is a very long SSH label" } }
          ]
        }
      };

      snapshotTimer.start();
    }
  }

  Timer {
    id: snapshotTimer
    interval: 80
    repeat: false
    onTriggered: {
      var logoProbe = panel.componentForWidget("logo").createObject(widgetProbeHost, {
        widgetInstance: {
          instanceId: "logo-probe",
          widgetType: "logo",
          enabled: true,
          settings: { displayMode: "full", labelText: "Very Long Launcher Label" }
        }
      });
      var dateTimeProbe = panel.componentForWidget("dateTime").createObject(widgetProbeHost, {
        widgetInstance: {
          instanceId: "clock-probe",
          widgetType: "dateTime",
          enabled: true,
          settings: { displayMode: "full", showDate: true }
        }
      });
      var cpuProbe = panel.componentForWidget("cpuStatus").createObject(widgetProbeHost, {
        widgetInstance: {
          instanceId: "cpu-probe",
          widgetType: "cpuStatus",
          enabled: true,
          settings: { displayMode: "full", valueStyle: "usageTemp" }
        }
      });

      results.logoProbe = {
        found: !!logoProbe,
        visible: logoProbe ? logoProbe.visible !== false : false,
        width: logoProbe ? Number(logoProbe.width || 0) : -1,
        implicitWidth: logoProbe ? Number(logoProbe.implicitWidth || 0) : -1,
        iconOnly: logoProbe ? !!logoProbe.iconOnly : null
      };
      results.dateTimeProbe = {
        found: !!dateTimeProbe,
        visible: dateTimeProbe ? dateTimeProbe.visible !== false : false,
        width: dateTimeProbe ? Number(dateTimeProbe.width || 0) : -1,
        implicitWidth: dateTimeProbe ? Number(dateTimeProbe.implicitWidth || 0) : -1,
        iconOnly: dateTimeProbe ? !!dateTimeProbe.iconOnly : null
      };
      results.cpuProbe = {
        found: !!cpuProbe,
        visible: cpuProbe ? cpuProbe.visible !== false : false,
        width: cpuProbe ? Number(cpuProbe.width || 0) : -1,
        implicitWidth: cpuProbe ? Number(cpuProbe.implicitWidth || 0) : -1,
        compact: cpuProbe ? !!cpuProbe.compact : null,
        iconOnly: cpuProbe ? !!cpuProbe.iconOnly : null
      };

      snapshot("windowTitle", "title-full");
      snapshot("wideDummy", "wide-dummy");
      snapshot("ssh", "ssh-vertical");
      console.log("RESULT:" + JSON.stringify(results));
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
  printf '[FAIL] vertical bar width harness exited with status %s.\n' "${status}" >&2
  exit 1
fi

grep -q 'RESULT:' <<<"${output}" || {
  printf '[FAIL] vertical bar width harness did not emit a RESULT payload.\n' >&2
  exit 1
}

result_line="$(printf '%s\n' "${output}" | sed -n 's/^.*RESULT://p' | tail -n 1)"

python - "${result_line}" <<'PY'
import json
import sys

results = json.loads(sys.argv[1])

def require(name):
    entry = results.get(name)
    if not entry or not entry.get("found"):
        print(f"[FAIL] Missing snapshot for {name}.", file=sys.stderr)
        sys.exit(1)
    return entry

window_title = require("windowTitle")
wide_dummy = require("wideDummy")
ssh = require("ssh")
logo_probe = require("logoProbe")
date_time_probe = require("dateTimeProbe")
cpu_probe = require("cpuProbe")

panel_width = window_title["panelWidth"]
panel_width_cap = window_title["panelWidthCap"]
item_width_cap = window_title["itemWidthCap"]

if panel_width <= 0 or panel_width > panel_width_cap:
    print("[FAIL] Vertical bar exceeded its width cap.", file=sys.stderr)
    sys.exit(1)

for name, entry in [("logo", logo_probe), ("dateTime", date_time_probe), ("cpu", cpu_probe)]:
    width = entry["width"] if entry["width"] > 0 else entry["implicitWidth"]
    if width <= 0 or width > item_width_cap:
        print(f"[FAIL] {name} did not stay within the vertical item width cap.", file=sys.stderr)
        sys.exit(1)
    if not entry["visible"]:
        print(f"[FAIL] {name} did not stay visible on the vertical bar.", file=sys.stderr)
        sys.exit(1)

if not logo_probe["iconOnly"]:
    print("[FAIL] Logo widget did not collapse to icon-only mode on the vertical bar.", file=sys.stderr)
    sys.exit(1)

if not date_time_probe["iconOnly"]:
    print("[FAIL] Date/time widget did not collapse to icon-only mode on the vertical bar.", file=sys.stderr)
    sys.exit(1)

if not cpu_probe["compact"] or cpu_probe["iconOnly"]:
    print("[FAIL] CPU widget did not collapse to compact mode on the vertical bar.", file=sys.stderr)
    sys.exit(1)

if window_title["width"] != 0 or window_title["height"] != 0:
    print("[FAIL] Window title was not hidden on the vertical bar.", file=sys.stderr)
    sys.exit(1)

if ssh["width"] != 0 or ssh["height"] != 0:
    print("[FAIL] SSH widget was not hidden on the vertical bar.", file=sys.stderr)
    sys.exit(1)

if wide_dummy["width"] != 0 or wide_dummy["height"] != 0:
    print("[FAIL] Unverified wide widget did not collapse on the vertical bar.", file=sys.stderr)
    sys.exit(1)
PY

grep -q 'widget=wideDummy instance=wide-dummy state=vertical-overflow' <<<"${output}" || {
  printf '[FAIL] Unverified wide widget did not report a vertical overflow diagnostic.\n' >&2
  exit 1
}

printf '[PASS] vertical bars stay within width limits and collapse unsupported wide widgets.\n'
