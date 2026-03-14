import QtQuick
import Quickshell
import "../../services"

Flow {
  id: root

  property var state: null
  property bool vertical: false
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

  Repeater {
    model: {
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
      return workspaces;
    }
    delegate: Rectangle {
      id: wsPill

      readonly property bool isActive: root.state && modelData.id === root.state.activeWorkspace
      readonly property bool isUrgent: !isActive && !!modelData.urgent

      radius: Colors.radiusXXS
      height: root.pillHeight
      width: Math.max(root.pillMinWidth, label.implicitWidth + 10)
      color: isActive ? root.activeColor : root.inactiveColor

      Behavior on color {
        enabled: !wsPill.isUrgent
        ColorAnimation { duration: Colors.durationFast }
      }

      SequentialAnimation on color {
        id: urgentAnim
        running: wsPill.isUrgent
        loops: Animation.Infinite
        ColorAnimation { to: root.urgentColor; duration: 600; easing.type: Easing.InOutSine }
        ColorAnimation { to: Colors.warning;   duration: 600; easing.type: Easing.InOutSine }
      }

      Text {
        id: label
        anchors.centerIn: parent
        color: root.textColor
        font.pixelSize: root.pillFontSize
        text: Config.workspaceShowNames && modelData.name ? modelData.name : String(modelData.id)
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: CompositorAdapter.focusWorkspace(modelData.id)
      }
    }
  }
}
