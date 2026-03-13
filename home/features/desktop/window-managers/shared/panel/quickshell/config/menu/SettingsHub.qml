import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "settings"

PanelWindow {
  id: settingsRoot

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  color: "transparent"
  visible: isOpen

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: (isOpen && !interactionBlocked) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell-settings"

  property bool isOpen: false
  property bool interactionBlocked: false
  property string currentTabId: SettingsRegistry.defaultTabId
  readonly property int currentTabIndex: SettingsRegistry.indexForTabId(currentTabId)
  signal browseWallpaper(string monitorName)
  signal pickWallpaperFolder()

  // Hyprland layout state (needed at open() time, stays on root)
  property real layoutGapsOut: 10
  property real layoutGapsIn: 5
  property real layoutActiveOpacity: 1.0
  property bool layoutIsMaster: false

  function refreshHyprlandSettings() {
    if (!hyprStateProc.running) hyprStateProc.running = true;
  }

  function open() {
    isOpen = true;
    refreshHyprlandSettings();
  }

  function close() {
    isOpen = false;
  }

  function toggle() {
    isOpen ? close() : open();
  }

  IpcHandler {
    target: "SettingsHub"
    function toggle() { settingsRoot.toggle(); }
    function open() { settingsRoot.open(); }
    function openTab(tabId: string) {
      var tab = SettingsRegistry.findTab(tabId);
      if (tab) settingsRoot.currentTabId = tab.id;
      settingsRoot.open();
    }
    function openIndex(index: int) {
      var tabId = SettingsRegistry.tabIdForIndex(index);
      if (tabId) settingsRoot.currentTabId = tabId;
      settingsRoot.open();
    }
    function close() { settingsRoot.close(); }
  }

  Process {
    id: hyprStateProc
    command: [
      "sh",
      "-c",
      "hyprctl getoption general:gaps_out -j 2>/dev/null; "
      + "printf '\\n'; "
      + "hyprctl getoption general:gaps_in -j 2>/dev/null; "
      + "printf '\\n'; "
      + "hyprctl getoption decoration:active_opacity -j 2>/dev/null; "
      + "printf '\\n'; "
      + "hyprctl getoption general:layout -j 2>/dev/null"
    ]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        try {
          if (lines[0]) {
            var gapsOut = JSON.parse(lines[0]);
            settingsRoot.layoutGapsOut = gapsOut.int !== undefined ? gapsOut.int : settingsRoot.layoutGapsOut;
          }
          if (lines[1]) {
            var gapsIn = JSON.parse(lines[1]);
            settingsRoot.layoutGapsIn = gapsIn.int !== undefined ? gapsIn.int : settingsRoot.layoutGapsIn;
          }
          if (lines[2]) {
            var activeOpacity = JSON.parse(lines[2]);
            settingsRoot.layoutActiveOpacity = activeOpacity.float !== undefined ? activeOpacity.float : settingsRoot.layoutActiveOpacity;
          }
          if (lines[3]) {
            var layout = JSON.parse(lines[3]);
            settingsRoot.layoutIsMaster = (layout.str === "master");
          }
        } catch (e) {
          console.error("Failed to parse Hyprland settings: " + e);
        }
      }
    }
  }

  // Background overlay
  MouseArea {
    enabled: !settingsRoot.interactionBlocked
    anchors.fill: parent
    onClicked: settingsRoot.close()

    Rectangle {
      anchors.fill: parent
      color: Colors.background
      opacity: 0.5
    }
  }

  // Main settings box
  Rectangle {
    id: mainBox
    enabled: !settingsRoot.interactionBlocked
    width: Math.min(parent.width - 40, 780)
    height: Math.min(parent.height - 40, 860)
    anchors.centerIn: parent
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge
    clip: true

    focus: settingsRoot.isOpen
    onVisibleChanged: if (visible) forceActiveFocus()
    Keys.onEscapePressed: settingsRoot.isOpen = false

    opacity: settingsRoot.isOpen ? 1.0 : 0.0
    scale: settingsRoot.isOpen ? 1.0 : 0.95
    Behavior on opacity { NumberAnimation { id: shFadeAnim; duration: 250; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { id: shScaleAnim; duration: 300; easing.type: Easing.OutBack } }
    layer.enabled: shFadeAnim.running || shScaleAnim.running

    // Prevent clicks from closing through the box
    MouseArea { anchors.fill: parent }

    RowLayout {
      anchors.fill: parent
      spacing: 0

      SettingsSidebar {
        currentTabId: settingsRoot.currentTabId
        onTabSelected: (tabId) => settingsRoot.currentTabId = tabId
        onSaveAndClose: {
          Config.save();
          settingsRoot.close();
        }
      }

      SettingsContent {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentTabId: settingsRoot.currentTabId
        settingsRoot: settingsRoot
      }
    }
  }
}
