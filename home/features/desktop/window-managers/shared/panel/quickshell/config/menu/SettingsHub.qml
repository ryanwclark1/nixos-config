import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../widgets" as SharedWidgets
import "settings"

PanelWindow {
  id: settingsRoot
  property var screenRef: Quickshell.cursorScreen || Config.primaryScreen()
  screen: screenRef
  readonly property var edgeMargins: Config.reservedEdgesForScreen(screenRef, "")
  readonly property int usableWidth: Math.max(0, width - edgeMargins.left - edgeMargins.right)
  readonly property int usableHeight: Math.max(0, height - edgeMargins.top - edgeMargins.bottom)
  readonly property bool isPortrait: usableHeight > usableWidth
  readonly property real gutterX: Math.min(56, Math.max(24, usableWidth * 0.04))
  readonly property real gutterY: Math.min(48, Math.max(24, usableHeight * 0.04))
  readonly property bool compactMode: isPortrait || usableWidth < 1024 || usableHeight < 760
  readonly property bool tightSpacing: usableWidth < 720 || usableHeight < 640
  readonly property int sidebarWidth: compactMode ? 72 : 256
  readonly property int maxLayerTextureSize: 4096
  property string searchQuery: ""

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
  property string currentTabId: _persist.currentTabId
  property var pendingBarWidgetTarget: null

  PersistentProperties {
    id: _persist
    reloadableId: "settingsHubState"
    property string currentTabId: SettingsRegistry.defaultTabId
  }
  property string pendingTabId: ""
  readonly property int currentTabIndex: SettingsRegistry.indexForTabId(currentTabId)
  signal browseWallpaper(string monitorName)
  signal pickWallpaperFolder()

  // Window-manager layout state (loaded from Hyprland options when supported).
  property real layoutGapsOut: 10
  property real layoutGapsIn: 5
  property real layoutActiveOpacity: 1.0
  property bool layoutIsMaster: false

  function refreshHyprlandSettings() {
    if (!CompositorAdapter.supportsHyprctlSettings) return;
    if (!hyprStateProc.running) hyprStateProc.running = true;
  }

  function open() {
    if (!SettingsRegistry.findTab(currentTabId))
      _persist.currentTabId = SettingsRegistry.defaultTabId;
    isOpen = true;
    if (CompositorAdapter.supportsHyprctlSettings) refreshHyprlandSettings();
  }

  function clearInteractiveFocus() {
    var item = settingsRoot.activeFocusItem;
    var depth = 0;
    while (item && depth < 24) {
      if (item.focus !== undefined)
        item.focus = false;
      item = item.parent;
      depth++;
    }
  }

  function close() {
    clearInteractiveFocus();
    isOpen = false;
  }

  function setCaptureScrollY(scrollY) {
    settingsContent.requestedScrollY = Math.max(0, Number(scrollY) || 0);
  }

  function captureOpenTab(tabId, scrollY) {
    setCurrentTab(tabId);
    pendingTabId = "";
    setCaptureScrollY(scrollY);
    open();
  }

  function setCurrentTab(tabId) {
    var tab = SettingsRegistry.findTab(tabId);
    if (!tab)
      return false;
    _persist.currentTabId = tab.id;
    return true;
  }

  function toggle() {
    isOpen ? close() : open();
  }

  function allowLayer(width, height) {
    return width > 0 && height > 0
      && width <= maxLayerTextureSize
      && height <= maxLayerTextureSize;
  }

  Timer {
    id: deferredOpenTimer
    interval: 1
    repeat: false
    onTriggered: {
      if (settingsRoot.pendingTabId) {
        settingsRoot.setCurrentTab(settingsRoot.pendingTabId);
        settingsRoot.pendingTabId = "";
      }
      settingsRoot.open();
    }
  }

  IpcHandler {
    target: "SettingsHub"
    function toggle() {
      Qt.callLater(() => settingsRoot.toggle());
    }
    function open() {
      Qt.callLater(() => settingsRoot.open());
    }
    function openTab(tabId: string) {
      Qt.callLater(() => {
        settingsRoot.pendingTabId = tabId;
        settingsRoot.setCaptureScrollY(0);
        deferredOpenTimer.restart();
      });
    }
    function openTabScrolled(tabId: string, scrollY: int) {
      settingsRoot.captureOpenTab(tabId, scrollY);
    }
    function openBarWidgetInstance(instanceId: string) {
      Qt.callLater(() => {
        var target = Config.findBarWidgetInstance(instanceId);
        settingsRoot.pendingBarWidgetTarget = target ? JSON.parse(JSON.stringify(target)) : null;
        settingsRoot.pendingTabId = "bar-widgets";
        settingsRoot.setCaptureScrollY(0);
        deferredOpenTimer.restart();
      });
    }
    function openIndex(index: int) {
      Qt.callLater(() => {
        settingsRoot.pendingTabId = SettingsRegistry.tabIdForIndex(index) || "";
        settingsRoot.setCaptureScrollY(0);
        deferredOpenTimer.restart();
      });
    }
    function close() {
      Qt.callLater(() => settingsRoot.close());
    }
  }

  Process {
    id: hyprStateProc
    command: CompositorAdapter.hyprlandSettingsSnapshotCommand()
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
          console.error("Failed to parse window-manager layout settings: " + e);
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
      color: Colors.withAlpha(Colors.background, Config.settingsBackdropOpacity)
    }
  }

  // Main settings box
  Rectangle {
    id: mainBox
    enabled: !settingsRoot.interactionBlocked
    width: Math.min(Math.max(320, settingsRoot.usableWidth - settingsRoot.gutterX * 2), 960)
    height: Math.min(Math.max(360, settingsRoot.usableHeight - settingsRoot.gutterY * 2), 920)
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: settingsRoot.edgeMargins.top + Math.max(settingsRoot.gutterY, (settingsRoot.usableHeight - height) / 2)
    anchors.leftMargin: settingsRoot.edgeMargins.left + Math.max(settingsRoot.gutterX, (settingsRoot.usableWidth - width) / 2)
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge
    clip: true


    // Inner highlight
    SharedWidgets.InnerHighlight { highlightOpacity: 0.15 }

    focus: settingsRoot.isOpen
    onVisibleChanged: {
      if (visible)
        forceActiveFocus()
      else {
        settingsRoot.clearInteractiveFocus();
        if (activeFocus)
        focus = false
      }
    }
    Keys.onEscapePressed: settingsRoot.isOpen = false

    opacity: settingsRoot.isOpen ? 1.0 : 0.0
    scale: settingsRoot.isOpen ? 1.0 : 0.95
    Behavior on opacity { NumberAnimation { id: shFadeAnim; duration: Colors.durationNormal; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { id: shScaleAnim; duration: Colors.durationSlow; easing.type: Easing.OutBack } }
    layer.enabled: (shFadeAnim.running || shScaleAnim.running) && settingsRoot.allowLayer(width, height)

    // Prevent clicks from closing through the box
    MouseArea { anchors.fill: parent }

    RowLayout {
      anchors.fill: parent
      spacing: 0

      SettingsSidebar {
        Layout.preferredWidth: settingsRoot.sidebarWidth
        currentTabId: settingsRoot.currentTabId
        searchQuery: settingsRoot.searchQuery
        compactMode: settingsRoot.compactMode
        onTabSelected: (tabId) => settingsRoot.setCurrentTab(tabId)
        onSearchQueryEdited: (query) => settingsRoot.searchQuery = query
        onSaveAndClose: {
          Config.save();
          settingsRoot.close();
        }
      }

      SettingsContent {
        id: settingsContent
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentTabId: settingsRoot.currentTabId
        settingsRoot: settingsRoot
        searchQuery: settingsRoot.searchQuery
        compactMode: settingsRoot.compactMode
        tightSpacing: settingsRoot.tightSpacing
        onTabSelected: (tabId) => settingsRoot.setCurrentTab(tabId)
        onSearchQueryEdited: (query) => settingsRoot.searchQuery = query
      }
    }
  }
}
