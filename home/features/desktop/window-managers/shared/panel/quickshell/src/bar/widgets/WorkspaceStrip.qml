import QtQuick
import Quickshell
import "../../services"

Flow {
  id: root

  property var state: null
  property bool vertical: false
  property bool showAddButton: true
  property bool showMiniMap: true
  property color activeColor: Config.workspaceActiveColor !== "" ? Config.workspaceActiveColor : Colors.highlight
  property color inactiveColor: Colors.surface
  property color textColor: Colors.text
  readonly property color urgentColor: Config.workspaceUrgentColor !== "" ? Config.workspaceUrgentColor : Colors.error

  // Pill size presets
  readonly property int pillHeight: Config.workspacePillSize === "compact" ? 16 : (Config.workspacePillSize === "large" ? 28 : 20)
  readonly property int pillMinWidth: Config.workspacePillSize === "compact" ? 18 : (Config.workspacePillSize === "large" ? 30 : 22)
  readonly property int pillFontSize: Config.workspacePillSize === "compact" ? Colors.fontSizeXS : (Config.workspacePillSize === "large" ? Colors.fontSizeMedium : Colors.fontSizeSmall)

  flow: vertical ? Flow.TopToBottom : Flow.LeftToRight
  spacing: Colors.spacingSM

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
      if (!Config.workspaceShowEmpty) {
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

      radius: Colors.radiusXXS
      height: root.pillHeight
      width: {
        var base = Math.max(root.pillMinWidth, label.implicitWidth + 12);
        if (windowCount > 0) return base + Math.min(windowCount * 8, 40);
        return base;
      }
      color: dropHighlight ? Colors.accent : (isActive ? root.activeColor : root.inactiveColor)

      Behavior on color {
        enabled: !wsPill.isUrgent
        ColorAnimation { duration: Colors.durationFast }
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
        ColorAnimation { to: root.urgentColor; duration: Colors.durationPulse; easing.type: Easing.InOutSine }
        ColorAnimation { to: Colors.warning;   duration: Colors.durationPulse; easing.type: Easing.InOutSine }
      }

      Text {
        id: label
        anchors.centerIn: parent
        color: wsPill.isActive ? Colors.background : root.textColor
        font.pixelSize: root.pillFontSize
        font.weight: wsPill.isActive ? Font.Bold : Font.Normal
        text: {
            var custom = WorkspaceIdentityService.getWorkspaceName(modelData.id);
            if (custom) return custom;
            return Config.workspaceShowNames && modelData.name ? modelData.name : String(modelData.id)
        }
        z: 2
      }

      // Live Mini-Map: dynamic window outlines
      Item {
        id: miniMap
        anchors.fill: parent
        anchors.margins: 2
        opacity: wsPill.isActive ? 0.4 : 0.6
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
            
            radius: Colors.radiusXXXS
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
                Quickshell.execDetached(["quickshell", "ipc", "call", "SurfaceService", "openSurface", "aiChat"]);
            } else {
                CompositorAdapter.focusWorkspace(modelData.id)
            }
        }
      }
    }
  }

  // ── Create Workspace Button ─────────────────
  Rectangle {
    id: addWsBtn
    width: root.pillMinWidth; height: root.pillHeight
    radius: Colors.radiusXXS
    color: addWsHover.containsMouse ? Colors.primarySubtle : Colors.cardSurface
    border.color: addWsHover.containsMouse ? Colors.primary : Colors.border
    border.width: 1
    visible: root.showAddButton && (Config.workspaceShowEmpty || root.state.workspaces.length < 10)
    
    Behavior on color { ColorAnimation { duration: Colors.durationFast } }
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
