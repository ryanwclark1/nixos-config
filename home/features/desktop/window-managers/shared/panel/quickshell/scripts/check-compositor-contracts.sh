#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
config_dir="${script_dir}/../config"

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

adapter_qml="${config_dir}/services/CompositorAdapter.qml"
title_qml="${config_dir}/bar/widgets/WindowTitle.qml"
dock_qml="${config_dir}/widgets/Dock.qml"
dock_content_qml="${config_dir}/widgets/DockContent.qml"
task_button_qml="${config_dir}/bar/widgets/TaskButton.qml"
taskbar_qml="${config_dir}/bar/widgets/Taskbar.qml"
launcher_qml="${config_dir}/launcher/Launcher.qml"

require_literal "$adapter_qml" 'import Quickshell.Hyprland' "Hyprland adapter import"
require_literal "$adapter_qml" 'property var hyprlandCtlWindow: ({})' "Hyprland fallback state property"
require_literal "$adapter_qml" 'command: ["hyprctl", "-j", "activewindow"]' "Hyprland activewindow fallback command"
require_literal "$adapter_qml" 'readonly property string activeWindowAppId: {' "normalized activeWindowAppId property"
require_literal "$adapter_qml" 'function windowIdentifier(windowRef) {' "window identifier helper"
require_literal "$adapter_qml" 'function windowAppId(windowRef) {' "window app id helper"
require_literal "$adapter_qml" 'function sameWindow(left, right) {' "stable window comparison helper"

require_literal "$title_qml" 'readonly property string activeTitle: CompositorAdapter.activeWindowTitle || ""' "window title widget uses normalized title"
require_literal "$title_qml" 'readonly property string activeAppId: CompositorAdapter.activeWindowAppId || ""' "window title widget uses normalized app id"
require_literal "$title_qml" 'implicitWidth: visible ? contentRow.implicitWidth : 0' "window title widget collapses width when hidden"

require_literal "$dock_qml" 'var tlAppId = CompositorAdapter.windowAppId(tl);' "dock uses normalized app id for pinned matching"
require_literal "$dock_qml" 'var tl2AppId = CompositorAdapter.windowAppId(tl2);' "dock uses normalized app id for unpinned grouping"
require_literal "$dock_content_qml" 'CompositorAdapter.sameWindow(toplevels[i], active)' "dock focus comparison uses stable window matching"
require_literal "$dock_content_qml" 'CompositorAdapter.sameWindow(appDelegate.toplevels[j], activeTop)' "dock grouped cycle uses stable window matching"
require_literal "$task_button_qml" 'return CompositorAdapter.windowAppId(aw).toLowerCase() === appClass.toLowerCase();' "task button uses normalized active window app id"
require_literal "$taskbar_qml" 'var tlCls = CompositorAdapter.windowAppId(tl);' "taskbar pinned lookup uses normalized app id"
require_literal "$taskbar_qml" 'var rtCls = CompositorAdapter.windowAppId(rt);' "taskbar running lookup uses normalized app id"
require_literal "$launcher_qml" 'var cls = CompositorAdapter.windowAppId(win);' "launcher window mode uses normalized app id"

printf '[INFO] Compositor contract check passed.\n'
