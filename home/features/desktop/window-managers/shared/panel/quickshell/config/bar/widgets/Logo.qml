import QtQuick
import Quickshell
import "../../services"
import "../../widgets" as SharedWidgets

Item {
  id: root
  width: 30
  height: 30
  implicitWidth: width
  implicitHeight: height

  property var anchorWindow: null
  property string tooltipText: "Applications • System Health: " + SystemStatus.overallStatus

  property color statusColor: {
    switch (SystemStatus.overallStatus) {
      case "healthy": return Colors.primary;
      case "warning": return Colors.warning;
      case "manual_review_required": return Colors.error;
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
    opacity: (SystemStatus.overallStatus === "healthy") ? 0 : 0.3
    visible: opacity > 0
    Behavior on color { ColorAnimation { duration: Colors.durationEmphasis } }
    Behavior on opacity { NumberAnimation { duration: Colors.durationEmphasis } }

    SequentialAnimation on opacity {
        running: SystemStatus.overallStatus !== "healthy"
        loops: Animation.Infinite
        NumberAnimation { from: 0.15; to: 0.45; duration: 1500; easing.type: Easing.InOutSine }
        NumberAnimation { from: 0.45; to: 0.15; duration: 1500; easing.type: Easing.InOutSine }
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

  Image {
    id: logoImage
    anchors.centerIn: parent
    sourceSize: Qt.size(20, 20)
    source: Quickshell.iconPath("nix-snowflake") || ""
    visible: status === Image.Ready
    // Apply status color to the image if it's a template
    layer.enabled: SystemStatus.overallStatus !== "healthy"
    layer.effect: ShaderEffect {
        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform highp float qt_Opacity;
            uniform lowp sampler2D source;
            uniform lowp vec4 color;
            void main() {
                lowp vec4 tex = texture2D(source, qt_TexCoord0);
                gl_FragColor = vec4(color.rgb, tex.a) * qt_Opacity;
            }"
        property color color: root.statusColor
    }
  }

  Text {
    anchors.centerIn: parent
    text: "󱄅"
    color: root.statusColor
    font.family: Colors.fontMono
    font.pixelSize: Colors.fontSizeXL
    visible: !logoImage.visible
  }

  scale: mouseArea.containsMouse ? 1.06 : 1.0
  layer.enabled: mouseArea.containsMouse
  Behavior on scale {
    NumberAnimation {
      duration: Colors.durationFast
      easing.type: Easing.OutCubic
    }
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
        logoMenu.popup(mouse.x, mouse.y);
      }
    }
  }

  SharedWidgets.ContextMenu {
    id: logoMenu
    model: [
        { label: "Check Health", icon: "󰓅", action: () => SystemStatus.refreshHealth() },
        { label: "Apply Safe Fixes", icon: "󰁨", action: () => SystemStatus.applySafeFixes(), visible: SystemStatus.activeIncidents.length > 0 },
        { label: "Open Health Dashboard", icon: "󰒓", action: () => Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", "health"]) },
        { separator: true },
        { label: "Restart Shell", icon: "󰑐", action: () => Quickshell.execDetached(["systemctl", "--user", "restart", "quickshell"]) }
    ]
  }

  SharedWidgets.BarTooltip {
    anchorItem: root
    anchorWindow: root.anchorWindow
    hovered: mouseArea.containsMouse
    text: root.tooltipText
  }
}
