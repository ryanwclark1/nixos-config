#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
config_dir="${QS_CONFIG_DIR:-${script_dir}/../src}"

require_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if rg -F -q -- "$needle" "$file"; then
    printf '[PASS] %s\n' "$label"
  else
    printf '[FAIL] Missing %s\n' "$label" >&2
    exit 1
  fi
}

forbid_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if rg -F -q -- "$needle" "$file"; then
    printf '[FAIL] Forbidden %s\n' "$label" >&2
    exit 1
  else
    printf '[PASS] %s absent\n' "$label"
  fi
}

adapter_qml="${config_dir}/services/CompositorAdapter.qml"
title_qml="${config_dir}/bar/widgets/WindowTitle.qml"
panel_qml="${config_dir}/bar/Panel.qml"
dock_qml="${config_dir}/features/dock/Dock.qml"
dock_content_qml="${config_dir}/features/dock/components/DockContent.qml"
dock_item_qml="${config_dir}/features/dock/components/DockItem.qml"
dock_indicators_qml="${config_dir}/features/dock/components/DockItemIndicators.qml"
task_button_qml="${config_dir}/bar/widgets/TaskButton.qml"
taskbar_qml="${config_dir}/bar/widgets/Taskbar.qml"
launcher_qml="${config_dir}/launcher/Launcher.qml"
launcher_delegate_qml="${config_dir}/launcher/LauncherResultDelegate.qml"

require_literal "$adapter_qml" 'import Quickshell.Hyprland' "Hyprland adapter import"
forbid_literal "$adapter_qml" 'property var hyprlandCtlWindow' "Hyprland polling fallback property (removed in favor of reactive bindings)"
forbid_literal "$adapter_qml" 'command: ["hyprctl", "-j", "activewindow"]' "Hyprland activewindow polling (removed in favor of reactive bindings)"
forbid_literal "$adapter_qml" 'reportHyprctlFailureState' "Hyprland polling failure reporter (removed with polling)"
require_literal "$adapter_qml" 'readonly property string activeWindowSource: {' "active window source property"
require_literal "$adapter_qml" 'readonly property bool activeWindowReady: activeWindowSource !== "none"' "active window ready property"
require_literal "$adapter_qml" 'readonly property string activeWindowDebugSummary: {' "active window debug summary"
require_literal "$adapter_qml" 'readonly property string activeWindowAppId: {' "normalized activeWindowAppId property"
require_literal "$adapter_qml" 'function windowIdentifier(windowRef) {' "window identifier helper"
require_literal "$adapter_qml" 'function windowAppId(windowRef) {' "window app id helper"
require_literal "$adapter_qml" 'function sameWindow(left, right) {' "stable window comparison helper"
require_literal "$adapter_qml" 'function workspaceNameById(wsId) {' "compositor-agnostic workspace name lookup"

require_literal "$title_qml" 'readonly property string activeTitle: CompositorAdapter.activeWindowTitle || ""' "window title widget uses normalized title"
require_literal "$title_qml" 'readonly property string activeAppId: CompositorAdapter.activeWindowAppId || ""' "window title widget uses normalized app id"
require_literal "$title_qml" 'implicitWidth: visible ? contentRow.implicitWidth : 0' "window title widget collapses width when hidden"

require_literal "$panel_qml" 'function reportWidgetDiagnostic(widgetId, state, details) {' "panel widget diagnostic reporter"
require_literal "$panel_qml" 'readonly property string diagnosticState: {' "panel widget diagnostic state"
forbid_literal "$panel_qml" 'visible: occupiesSpace' "delegate visibility cycle"

require_literal "$dock_qml" 'var tlAppId = CompositorAdapter.windowAppId(tl);' "dock uses normalized app id for pinned matching"
require_literal "$dock_qml" 'var tl2AppId = CompositorAdapter.windowAppId(tl2);' "dock uses normalized app id for unpinned grouping"
require_literal "$dock_item_qml" 'var active = CompositorAdapter.activeWindow;' "dock focus path uses normalized active window"
require_literal "$dock_item_qml" 'CompositorAdapter.sameWindow(toplevels[i], active)' "dock focus comparison uses stable window matching"
require_literal "$dock_item_qml" 'CompositorAdapter.sameWindow(root.toplevels[i], active)' "dock grouped cycle uses stable window matching"
forbid_literal "$dock_item_qml" 'CompositorAdapter.activeToplevel' "dock direct activeToplevel access"
require_literal "$task_button_qml" 'return CompositorAdapter.windowAppId(aw).toLowerCase() === appId.toLowerCase();' "task button uses normalized active window app id"
require_literal "$task_button_qml" 'taskItem.pinToggled({ appId: appId, title: appName, exec: appExec });' "task button pin payload uses appId"
require_literal "$taskbar_qml" 'function pinnedAppId(app) {' "taskbar pinned-app helper"
require_literal "$taskbar_qml" 'var tlAppId = CompositorAdapter.windowAppId(tl);' "taskbar pinned lookup uses normalized app id"
require_literal "$taskbar_qml" 'var rtAppId = CompositorAdapter.windowAppId(rt);' "taskbar running lookup uses normalized app id"
require_literal "$taskbar_qml" 'appId: itemData.appId || ""' "taskbar passes normalized app id to buttons"
require_literal "$launcher_qml" 'var appId = CompositorAdapter.windowAppId(win);' "launcher window mode uses normalized app id"
require_literal "$launcher_qml" 'var address = CompositorAdapter.windowIdentifier(win);' "launcher window mode uses stable window address"
require_literal "$launcher_qml" 'appId: item.appId || "",' "launcher recent items persist normalized app id"
require_literal "$launcher_delegate_qml" 'var windowAppId = String(it.appId || it.class || "");' "launcher delegate prefers normalized app id"

printf '[INFO] Compositor contract check passed.\n'
