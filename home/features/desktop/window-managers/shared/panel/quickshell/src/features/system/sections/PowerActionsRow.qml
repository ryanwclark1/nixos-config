import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

RowLayout {
  id: root
  Layout.fillWidth: true
  spacing: Colors.paddingSmall

  property bool showContent: false
  property int baseIndex: 14
  property int staggerDelay: 35
  property int pendingPowerIndex: -1

  opacity: showContent ? 1.0 : 0.0
  scale: showContent ? 1.0 : 0.96
  transform: Translate { y: showContent ? 0 : 8 }

  Behavior on opacity { SequentialAnimation { PauseAnimation { duration: showContent ? (root.baseIndex * root.staggerDelay) : 0 } NumberAnimation { duration: Colors.durationNormal + (root.baseIndex * 20); easing.type: Easing.OutCubic } } }
  Behavior on scale { SequentialAnimation { PauseAnimation { duration: showContent ? (root.baseIndex * root.staggerDelay) : 0 } NumberAnimation { duration: Colors.durationNormal + (root.baseIndex * 20); easing.type: Easing.OutBack } } }
  Behavior on transform { SequentialAnimation { PauseAnimation { duration: showContent ? (root.baseIndex * root.staggerDelay) : 0 } NumberAnimation { duration: Colors.durationNormal + (root.baseIndex * 20); easing.type: Easing.OutCubic } } }

  Timer {
    id: powerConfirmTimer
    interval: 3000
    onTriggered: root.pendingPowerIndex = -1
  }

  Repeater {
    model: SystemActionRegistry.actionsByIds([
      "shutdown",
      "reboot",
      "lock"
    ])
    delegate: Rectangle {
      required property var modelData
      required property int index
      readonly property bool awaitingConfirm: root.pendingPowerIndex === index
      Layout.fillWidth: true
      height: 40
      color: awaitingConfirm ? Colors.error : Colors.surface
      radius: Colors.radiusXS
      border.color: Colors.border
      border.width: 1
      Behavior on color { ColorAnimation { duration: Colors.durationFast } }

      // Inner highlight border
      SharedWidgets.InnerHighlight { highlightOpacity: 0.15 }

      Text {
        anchors.centerIn: parent
        text: awaitingConfirm ? "Confirm?" : modelData.icon
        color: awaitingConfirm ? Colors.background : Colors.text
        font.family: awaitingConfirm ? undefined : Colors.fontMono
        font.pixelSize: awaitingConfirm ? Colors.fontSizeSmall : Colors.fontSizeXL
        font.weight: awaitingConfirm ? Font.Bold : Font.Normal
      }

      SharedWidgets.StateLayer {
        id: powerStateLayer
        hovered: powerHover.containsMouse
        pressed: powerHover.pressed
      }

      MouseArea {
        id: powerHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
          powerStateLayer.burst(mouse.x, mouse.y);
          if (!modelData.requiresConfirmation) {
            SystemActionRegistry.execute(modelData.id);
            return;
          }
          if (awaitingConfirm) {
            SystemActionRegistry.execute(modelData.id);
            root.pendingPowerIndex = -1;
            powerConfirmTimer.stop();
          } else {
            root.pendingPowerIndex = index;
            powerConfirmTimer.restart();
          }
        }
      }
    }
  }
}
