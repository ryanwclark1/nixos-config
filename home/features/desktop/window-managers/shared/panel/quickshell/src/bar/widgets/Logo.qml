import QtQuick
import Quickshell
import "../../services"
import "../../shared"
import "../../widgets" as SharedWidgets

Item {
  id: root
  width: iconOnly ? 30 : Math.max(30, logoRow.implicitWidth + 12)
  height: 30
  implicitWidth: width
  implicitHeight: height

  property var anchorWindow: null
  property string tooltipText: "Applications • System Health: " + SystemStatus.overallStatus
  property bool iconOnly: true
  property string labelText: "Apps"

  signal contextMenuRequested(var actions, var triggerRect)

  property color statusColor: {
    switch (SystemStatus.overallStatus) {
      case "healthy": return Colors.primary;
      case "warning": return Colors.warning;
      case "manual_review_required": return Colors.warning;
      case "failure": return Colors.error;
      default: return Colors.primary;
    }
  }

  Rectangle {
    id: statusGlow
    anchors.fill: parent
    anchors.margins: -2
    radius: Colors.radiusSmall
    color: root.statusColor
    opacity: SystemStatus.overallStatus === "healthy" ? 0
           : SystemStatus.overallStatus === "warning" ? 0.18
           : 0.3
    visible: opacity > 0
    Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Colors.durationEmphasis } }

    SequentialAnimation on opacity {
        id: pulseAnim
        property bool isFailure: SystemStatus.overallStatus === "failure"
        running: SystemStatus.overallStatus === "failure"
              || SystemStatus.overallStatus === "manual_review_required"
        loops: Animation.Infinite
        NumberAnimation {
            from: pulseAnim.isFailure ? 0.15 : 0.10
            to: pulseAnim.isFailure ? 0.45 : 0.25
            duration: pulseAnim.isFailure ? 1500 : 2000
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            from: pulseAnim.isFailure ? 0.45 : 0.25
            to: pulseAnim.isFailure ? 0.15 : 0.10
            duration: pulseAnim.isFailure ? 1500 : 2000
            easing.type: Easing.InOutSine
        }
    }
  }

  Rectangle {
    id: logoBg
    anchors.fill: parent
    radius: Colors.radiusSmall
    color: "transparent"

    SharedWidgets.StateLayer {
      id: stateLayer
      hovered: mouseArea.containsMouse
      pressed: mouseArea.pressed
      stateColor: root.statusColor
    }
  }

  Row {
    id: logoRow
    anchors.centerIn: parent
    spacing: Colors.spacingXS

    Image {
      id: logoImage
      anchors.verticalCenter: parent.verticalCenter
      sourceSize: Qt.size(20, 20)
      source: Quickshell.iconPath("nix-snowflake") || ""
      visible: status === Image.Ready && SystemStatus.overallStatus !== "failure"
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "󱄅"
      color: root.statusColor
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeXL
      visible: !logoImage.visible
    }

    Text {
      visible: !root.iconOnly
      anchors.verticalCenter: parent.verticalCenter
      text: root.labelText
      color: Colors.text
      font.pixelSize: Colors.fontSizeSmall
      font.weight: Font.DemiBold
    }
  }

  scale: mouseArea.containsMouse ? 1.06 : 1.0
  layer.enabled: mouseArea.containsMouse
  Behavior on scale {
    Anim { duration: Colors.durationFast }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
      stateLayer.burst(mouse.x, mouse.y);
      if (mouse.button === Qt.LeftButton) {
        Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "openDrun"]);
      } else {
        var globalPos = root.mapToItem(null, 0, 0);
        root.contextMenuRequested([
            { label: "Check Health", icon: "󰓅", action: () => SystemStatus.refreshHealth() },
            { label: "Apply Safe Fixes", icon: "󰁨", action: () => SystemStatus.applySafeFixes(), visible: SystemStatus.activeIncidents.length > 0 },
            { label: "Open Health Dashboard", icon: "󰒓", action: () => Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", "health"]) },
            { separator: true },
            { label: "Restart Shell", icon: "arrow-clockwise.svg", action: () => Quickshell.execDetached(["systemctl", "--user", "restart", "quickshell"]) }
        ], { x: globalPos.x, y: globalPos.y, width: root.width, height: root.height });
      }
    }
  }

  SharedWidgets.BarTooltip {
    anchorItem: root
    anchorWindow: root.anchorWindow
    hovered: mouseArea.containsMouse
    text: root.tooltipText
  }
}
