#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
repo_root="$(git -C "${script_dir}" rev-parse --show-toplevel)"
config_root="${repo_root}/home/features/desktop/window-managers/shared/panel/quickshell/config"

width=900
height=700
tab_id="wallpaper"
output_path=""
delay_seconds="4"
scroll_y="0"
workspace_target="auto"
temp_qml=""
temp_full=""
temp_crop=""
harness_pid=""
restore_workspace=""

usage() {
  cat <<'EOF'
Usage: capture-settings-viewport.sh [--width PX] [--height PX] [--tab TAB_ID] [--delay SECONDS] [--scroll-y PX] [--workspace current|auto|NAME] [--output PATH]

Render the settings UI inside a temporary overlay harness at a simulated viewport size,
capture a cropped screenshot, and save it to a file.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --width)
      width="${2:-}"
      shift 2
      ;;
    --height)
      height="${2:-}"
      shift 2
      ;;
    --tab)
      tab_id="${2:-}"
      shift 2
      ;;
    --delay)
      delay_seconds="${2:-}"
      shift 2
      ;;
    --scroll-y)
      scroll_y="${2:-}"
      shift 2
      ;;
    --workspace)
      workspace_target="${2:-}"
      shift 2
      ;;
    --output)
      output_path="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 2
  fi
}

pick_capture_workspace() {
  local used
  for candidate in $(seq 9001 9099); do
    used="$(hyprctl workspaces -j | jq --arg candidate "${candidate}" 'map(select((.name // "") == $candidate or ((.id | tostring) == $candidate))) | length')"
    if [[ "${used}" == "0" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

switch_to_capture_workspace() {
  local requested="$1"
  local target="${requested}"
  if [[ "${requested}" == "current" ]]; then
    return 0
  fi

  restore_workspace="$(hyprctl -j activeworkspace | jq -r '.name // (.id | tostring)')"
  if [[ -z "${restore_workspace}" || "${restore_workspace}" == "null" ]]; then
    printf 'Could not resolve active workspace before capture.\n' >&2
    exit 1
  fi

  if [[ "${requested}" == "auto" ]]; then
    target="$(pick_capture_workspace)" || {
      printf 'Could not allocate a dedicated capture workspace.\n' >&2
      exit 1
    }
  fi

  hyprctl dispatch workspace "${target}" >/dev/null
}

main() {
  require_cmd quickshell
  require_cmd hyprctl
  require_cmd jq
  require_cmd grim
  require_cmd magick
  require_cmd mktemp
  require_cmd git

  if ! [[ "${width}" =~ ^[0-9]+$ ]] || ! [[ "${height}" =~ ^[0-9]+$ ]]; then
    printf 'Width and height must be integers.\n' >&2
    exit 2
  fi
  if ! [[ "${delay_seconds}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf 'Delay must be numeric.\n' >&2
    exit 2
  fi
  if ! [[ "${scroll_y}" =~ ^[0-9]+$ ]]; then
    printf 'scroll-y must be a non-negative integer.\n' >&2
    exit 2
  fi

  if [[ -z "${output_path}" ]]; then
    output_path="/tmp/settings-${tab_id}-${width}x${height}.png"
  fi

  temp_qml="$(mktemp /tmp/settings-viewport-harness-XXXXXX.qml)"
  temp_full="$(mktemp /tmp/settings-viewport-full-XXXXXX.png)"
  temp_crop="$(mktemp /tmp/settings-viewport-crop-XXXXXX.png)"

  trap '[[ -n "${harness_pid}" ]] && kill "${harness_pid}" >/dev/null 2>&1 || true; [[ -n "${restore_workspace}" ]] && hyprctl dispatch workspace "${restore_workspace}" >/dev/null 2>&1 || true; rm -f "${temp_qml}" "${temp_full}" "${temp_crop}"' EXIT

  switch_to_capture_workspace "${workspace_target}"

  cat >"${temp_qml}" <<EOF
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "file:${config_root}/services"
import "file:${config_root}/menu/settings"

PanelWindow {
  id: root
  screen: Quickshell.screens[0]
  color: "transparent"
  visible: true
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  WlrLayershell.namespace: "settings-viewport-harness"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  property int previewWidth: ${width}
  property int previewHeight: ${height}
  property int requestedScrollY: ${scroll_y}
  property int scrollApplyAttemptsRemaining: 12
  property string initialTabId: "${tab_id}"
  property string currentTabId: SettingsRegistry.defaultTabId
  property string searchQuery: ""
  readonly property bool compactMode: previewHeight > previewWidth || previewWidth < 1024 || previewHeight < 760
  readonly property bool tightSpacing: previewWidth < 720 || previewHeight < 640
  readonly property int sidebarWidth: compactMode ? 72 : 256
  property QtObject settingsRoot: QtObject {
    property real layoutGapsOut: 10
    property real layoutGapsIn: 5
    property real layoutActiveOpacity: 1.0
    property bool layoutIsMaster: false
    signal browseWallpaper(string monitorName)
    signal pickWallpaperFolder()
    function close() {}
  }

  Rectangle {
    anchors.fill: parent
    color: Colors.withAlpha(Colors.background, 0.72)
  }

  Component.onCompleted: {
    if (SettingsRegistry.findTab(initialTabId))
      currentTabId = initialTabId;
  }

  function applyScroll(node) {
    if (!node)
      return;
    if (node.contentY !== undefined && node.contentHeight !== undefined && node.height !== undefined) {
      var maxY = Math.max(0, node.contentHeight - node.height);
      node.contentY = Math.min(requestedScrollY, maxY);
    }
    var kids = [];
    if (node.children)
      kids = kids.concat(node.children);
    if (node.contentItem)
      kids.push(node.contentItem);
    if (node.flickable)
      kids.push(node.flickable);
    if (node.item)
      kids.push(node.item);
    for (var i = 0; i < kids.length; i++)
      applyScroll(kids[i]);
  }

  Timer {
    interval: 0
    running: true
    repeat: false
    onTriggered: {
      if (SettingsRegistry.findTab(root.initialTabId))
        root.currentTabId = root.initialTabId;
      applyScroll(root);
    }
  }

  Timer {
    interval: 150
    running: true
    repeat: true
    onTriggered: {
      if (SettingsRegistry.findTab(root.initialTabId))
        root.currentTabId = root.initialTabId;
      applyScroll(root);
      root.scrollApplyAttemptsRemaining -= 1;
      if (root.scrollApplyAttemptsRemaining <= 0)
        stop();
    }
  }

  Rectangle {
    width: root.previewWidth
    height: root.previewHeight
    anchors.centerIn: parent
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge
    clip: true

    RowLayout {
      anchors.fill: parent
      spacing: 0

      SettingsSidebar {
        Layout.preferredWidth: root.sidebarWidth
        compactMode: root.compactMode
        currentTabId: root.currentTabId
        searchQuery: root.searchQuery
        onTabSelected: tabId => root.currentTabId = tabId
        onSearchQueryEdited: query => root.searchQuery = query
        onSaveAndClose: Config.save()
      }

      SettingsContent {
        Layout.fillWidth: true
        Layout.fillHeight: true
        compactMode: root.compactMode
        currentTabId: root.currentTabId
        searchQuery: root.searchQuery
        settingsRoot: root.settingsRoot
        tightSpacing: root.tightSpacing
        onTabSelected: tabId => root.currentTabId = tabId
        onSearchQueryEdited: query => root.searchQuery = query
      }
    }
  }
}
EOF

  quickshell --path "${temp_qml}" >/tmp/settings-viewport-harness.log 2>&1 &
  harness_pid=$!
  sleep "${delay_seconds}"

  local monitor_json monitor_x monitor_y monitor_w monitor_h reserved_top reserved_right reserved_bottom reserved_left usable_w usable_h crop_x crop_y
  monitor_json="$(hyprctl monitors -j | jq 'map(select(.focused == true))[0]')"
  monitor_x="$(printf '%s' "${monitor_json}" | jq -r '.x')"
  monitor_y="$(printf '%s' "${monitor_json}" | jq -r '.y')"
  monitor_w="$(printf '%s' "${monitor_json}" | jq -r '.width')"
  monitor_h="$(printf '%s' "${monitor_json}" | jq -r '.height')"
  reserved_top="$(printf '%s' "${monitor_json}" | jq -r '.reserved[0]')"
  reserved_left="$(printf '%s' "${monitor_json}" | jq -r '.reserved[1]')"
  reserved_bottom="$(printf '%s' "${monitor_json}" | jq -r '.reserved[2]')"
  reserved_right="$(printf '%s' "${monitor_json}" | jq -r '.reserved[3]')"

  usable_w=$((monitor_w - reserved_left - reserved_right))
  usable_h=$((monitor_h - reserved_top - reserved_bottom))

  crop_x=$((monitor_x + reserved_left + (usable_w - width) / 2))
  crop_y=$((monitor_y + reserved_top + (usable_h - height) / 2))

  grim -t png "${temp_full}"
  magick "${temp_full}" -crop "${width}x${height}+${crop_x}+${crop_y}" +repage "${temp_crop}"
  cp "${temp_crop}" "${output_path}"

  printf '[INFO] Captured %s at %sx%s -> %s\n' "${tab_id}" "${width}" "${height}" "${output_path}"
}

main "$@"
