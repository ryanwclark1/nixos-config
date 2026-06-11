import QtQuick
import Quickshell
import "../../services"
import "../../services/ShellUtils.js" as SU
import "../../shared"

Flow {
  id: root

  property var state: null
  property var settings: ({})
  property bool vertical: false
  property real iconScale: 1.0
  property real fontScale: 1.0

  readonly property bool showEmpty: settings.hasOwnProperty("showEmpty") ? settings.showEmpty : Config.workspaceShowEmpty
  property bool showAddButton: settings.hasOwnProperty("showAddButton") ? settings.showAddButton : Config.workspaceShowAddButton
  property bool showMiniMap: settings.hasOwnProperty("showMiniMap") ? settings.showMiniMap : Config.workspaceShowMiniMap
  readonly property bool showNames: settings.hasOwnProperty("showNames") ? settings.showNames : Config.workspaceShowNames
  readonly property bool showAppIcons: settings.hasOwnProperty("showAppIcons") ? settings.showAppIcons : Config.workspaceShowAppIcons
  readonly property bool showWindowCount: settings.hasOwnProperty("showWindowCount") ? settings.showWindowCount : Config.workspaceShowWindowCount
  readonly property int maxIcons: settings.hasOwnProperty("maxIcons") ? settings.maxIcons : Config.workspaceMaxIcons
  readonly property string pillSize: settings.hasOwnProperty("pillSize") ? settings.pillSize : Config.workspacePillSize
  readonly property string style: settings.hasOwnProperty("style") ? settings.style : Config.workspaceStyle
  readonly property string layout: settings.hasOwnProperty("layout") ? settings.layout : Config.workspaceLayout
  readonly property string clickBehavior: settings.hasOwnProperty("clickBehavior") ? settings.clickBehavior : Config.workspaceClickBehavior

  property color activeColor: Config.workspaceActiveColor !== "" ? Config.workspaceActiveColor : Colors.highlight
  property color inactiveColor: Colors.surface
  property color textColor: Colors.text
  readonly property color urgentColor: Config.workspaceUrgentColor !== "" ? Config.workspaceUrgentColor : Colors.error

  // Pill size presets
  readonly property int pillHeight: (pillSize === "compact" ? 16 : (pillSize === "large" ? 28 : 20)) * iconScale
  readonly property int pillMinWidth: (pillSize === "compact" ? 18 : (pillSize === "large" ? 30 : 22)) * iconScale
  readonly property int pillFontSize: (pillSize === "compact" ? Appearance.fontSizeXS : (pillSize === "large" ? Appearance.fontSizeMedium : Appearance.fontSizeSmall)) * fontScale

  readonly property bool isGrid: layout === "grid"
  
  flow: vertical ? Flow.TopToBottom : (isGrid ? Flow.LeftToRight : Flow.LeftToRight)
  spacing: Appearance.spacingSM * iconScale

  // Helper for click behavior
  function handleWorkspaceClick(wsId) {
    if (clickBehavior === "last_window") {
      // Find the last active window on this workspace
      var wsList = root.state ? root.state.workspaces : [];
      var wsData = null;
      for (var i = 0; i < wsList.length; i++) {
        if (wsList[i].id === wsId) { wsData = wsList[i]; break; }
      }
      
      if (wsData && wsData.windowData && wsData.windowData.length > 0) {
        // Find the one that was most recently active if possible, 
        // or just the first one marked active in the data
        var targetWin = wsData.windowData[0];
        for (var j = 0; j < wsData.windowData.length; j++) {
          if (wsData.windowData[j].active) { targetWin = wsData.windowData[j]; break; }
        }
        
        if (targetWin && targetWin.address) {
          CompositorAdapter.focusWindow(targetWin.address);
          return;
        }
      }
    }
    
    // Default or fallback
    CompositorAdapter.focusWorkspace(wsId);
  }

  // Scroll-to-switch workspace
  WheelHandler {
    enabled: Config.workspaceScrollEnabled
    onWheel: event => {
      var delta = Config.workspaceReverseScroll ? -event.angleDelta.y : event.angleDelta.y;
      if (delta > 0)
        CompositorAdapter.focusWorkspace("e-1");
      else if (delta < 0)
        CompositorAdapter.focusWorkspace("e+1");
    }
  }

  ScriptModel {
    id: _wsModel
    values: {
      var workspaces = root.state ? root.state.workspaces : [];
      if (!root.showEmpty) {
        var filtered = [];
        for (var i = 0; i < workspaces.length; i++) {
          var ws = workspaces[i];
          var isActive = root.state && ws.id === root.state.activeWorkspace;
          var hasWindows = ws.windows !== undefined ? ws.windows > 0 : true;
          if (isActive || hasWindows || ws.urgent)
            filtered.push(ws);
        }
        return filtered;
      }
      return [...workspaces];
    }
  }

  Repeater {
    model: _wsModel
    delegate: Rectangle {
      id: wsPill

      readonly property bool isActive: root.state && modelData.id === root.state.activeWorkspace
      readonly property bool isUrgent: !isActive && !!modelData.urgent
      readonly property int windowCount: modelData.windows || 0
      property bool dropHighlight: false

      readonly property bool isDots: root.style === "dots"
      readonly property bool isStrip: root.style === "strip"
      readonly property bool isIcons: root.style === "icons"

      radius: isDots ? width / 2 : Appearance.radiusXXS
      height: root.pillHeight
      width: {
        if (isDots) return root.pillHeight;
        if (isStrip) return isActive ? root.pillMinWidth * 2 : root.pillMinWidth;
        
        return Math.max(root.pillMinWidth, label.implicitWidth + 12);
      }
      color: dropHighlight ? Colors.accent : (isActive ? root.activeColor : root.inactiveColor)

      Behavior on width {
        enabled: !Colors.isTransitioning
        NumberAnimation { duration: Appearance.durationNormal; easing.type: Easing.OutCubic }
      }

      Behavior on color {
        enabled: !wsPill.isUrgent && !Colors.isTransitioning
        CAnim {}
      }

      DropArea {
        anchors.fill: parent
        keys: ["window", "overview-window"]
        onEntered: wsPill.dropHighlight = true
        onExited: wsPill.dropHighlight = false
        onDropped: (drop) => {
          wsPill.dropHighlight = false;
          if (drop.source && (drop.source.windowAddress || drop.source.windowId)) {
            var addr = drop.source.windowAddress || drop.source.windowId;
            CompositorAdapter.moveWindowToWorkspace(addr, modelData.id);
          }
        }
      }

      SequentialAnimation on color {
        id: urgentAnim
        running: wsPill.isUrgent
        loops: Animation.Infinite
        ColorAnimation { to: root.urgentColor; duration: Appearance.durationPulse; easing.type: Easing.InOutSine }
        ColorAnimation { to: Colors.warning;   duration: Appearance.durationPulse; easing.type: Easing.InOutSine }
      }

      Text {
        id: label
        anchors.centerIn: parent
        color: wsPill.isActive ? Colors.background : root.textColor
        font.pixelSize: root.pillFontSize
        font.weight: wsPill.isActive ? Font.Bold : Font.Normal
        visible: !wsPill.isDots
        text: {
            if (wsPill.isIcons) {
                var icons = ["󰎤", "󰎧", "󰎪", "󰎭", "󰎱", "󰎳", "󰎶", "󰎹", "󰎼", "󰽽"];
                var idx = (modelData.id - 1) % 10;
                return icons[idx] || String(modelData.id);
            }
            var custom = WorkspaceIdentityService.getWorkspaceName(modelData.id);
            if (custom) return custom;
            return root.showNames && modelData.name ? modelData.name : String(modelData.id)
        }
        z: 2
      }

      // Window count indicator
      Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: -4 * root.iconScale
        width: 14 * root.iconScale; height: 14 * root.iconScale
        radius: width / 2
        color: Colors.accent
        visible: root.showWindowCount && wsPill.windowCount > 0
        z: 3

        Text {
          anchors.centerIn: parent
          text: String(wsPill.windowCount)
          color: Colors.background
          font.pixelSize: 9 * root.fontScale
          font.weight: Font.Bold
        }
      }

      // Live Mini-Map: dynamic window outlines
      Item {
        id: miniMap
        anchors.fill: parent
        anchors.margins: 2 * root.iconScale
        visible: root.showMiniMap && !!(modelData && modelData.windowData && modelData.windowData.length > 0)
        z: 1

        Repeater {
          model: modelData.windowData || []
          delegate: Rectangle {
            // Find screen dimensions to normalize coordinates
            readonly property real screenW: root.anchorWindow ? root.anchorWindow.width : 1920
            readonly property real screenH: root.anchorWindow ? root.anchorWindow.height : 1080
            
            x: (modelData.x / screenW) * parent.width
            y: (modelData.y / screenH) * parent.height
            width: Math.max(2, (modelData.w / screenW) * parent.width)
            height: Math.max(2, (modelData.h / screenH) * parent.height)
            
            radius: Appearance.radiusXXXS
            color: wsPill.isActive ? Colors.background : (modelData.active ? Colors.primary : Colors.textSecondary)
            opacity: modelData.active ? 0.8 : 0.4
            border.color: wsPill.isActive ? Colors.background : Colors.border
            border.width: modelData.active ? 1 : 0
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                // Inline rename logic using a simple input dialog or just a command
                // For now, we'll use a prompt via IPC to the AI assistant to rename it
                var current = WorkspaceIdentityService.getWorkspaceName(modelData.id);
                AiService.sendMessage("Rename workspace " + modelData.id + " from '" + current + "' to: ");
                Quickshell.execDetached(SU.ipcCall("SurfaceService", "openSurface", "aiChat"));
            } else {
                root.handleWorkspaceClick(modelData.id)
            }
        }
      }
    }
  }

  // ── Create Workspace Button ─────────────────
  Rectangle {
    id: addWsBtn
    width: root.pillMinWidth; height: root.pillHeight
    radius: Appearance.radiusXXS
    color: addWsHover.containsMouse ? Colors.primarySubtle : Colors.cardSurface
    border.color: addWsHover.containsMouse ? Colors.primary : Colors.border
    border.width: 1
    visible: root.showAddButton && (Config.workspaceShowEmpty || root.state.workspaces.length < 10)
    
    Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
    scale: addWsHover.containsMouse ? 1.1 : 1.0
    Behavior on scale { SpringAnimation { spring: 4; damping: 0.3 } }

    Text {
      anchors.centerIn: parent
      text: "+"
      color: addWsHover.containsMouse ? Colors.primary : Colors.textDisabled
      font.pixelSize: root.pillFontSize
      font.weight: Font.Light
    }

    DropArea {
      anchors.fill: parent
      keys: ["window", "overview-window"]
      onEntered: addWsBtn.color = Colors.withAlpha(Colors.accent, 0.2)
      onExited: addWsBtn.color = Colors.cardSurface
      onDropped: (drop) => {
        if (drop.source && (drop.source.windowAddress || drop.source.windowId)) {
          var addr = drop.source.windowAddress || drop.source.windowId;
          // Create new workspace and move window there
          var nextId = root.state.workspaces.length + 1;
          CompositorAdapter.moveWindowToWorkspace(addr, nextId);
        }
      }
    }

    MouseArea {
      id: addWsHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        var nextId = root.state.workspaces.length + 1;
        CompositorAdapter.focusWorkspace(nextId);
      }
    }
  }
}
