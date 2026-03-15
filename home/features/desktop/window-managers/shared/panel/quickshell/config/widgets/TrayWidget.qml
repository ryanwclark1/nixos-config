import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../services"


Flow {
  id: root
  spacing: Colors.spacingS
  property bool vertical: false
  flow: vertical ? Flow.TopToBottom : Flow.LeftToRight
  property var anchorWindow: null

  Repeater {
    model: SystemTray.items

    delegate: Rectangle {
      id: trayItem
      width: 24
      height: 24
      radius: Colors.radiusXXS
      color: "transparent"
      scale: mouseArea.containsMouse ? 1.08 : 1.0

      Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }

      Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        source: modelData.icon || ""
        asynchronous: true

        // Fallback icon if none found
        Text {
          anchors.centerIn: parent
          text: "󰏘"
          color: Colors.textSecondary
          font.pixelSize: Colors.fontSizeMedium
          visible: parent.status !== Image.Ready
        }
      }

      StateLayer {
        id: stateLayer
        hovered: mouseArea.containsMouse
        pressed: mouseArea.pressed
        stateColor: Colors.primary
      }

      MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
          stateLayer.burst(mouse.x, mouse.y);
          if (mouse.button === Qt.RightButton) {
            if (modelData.hasMenu) {
              try {
                var win = root.Window.window;
                if (win) {
                  var pos = trayItem.mapToItem(null, 0, trayItem.height);
                  modelData.display(win, Math.round(pos.x), Math.round(pos.y));
                }
              } catch (e) {
                console.warn("TrayWidget: failed to display menu:", e);
              }
            } else if (modelData.secondaryActivate) {
              modelData.secondaryActivate();
            }
          } else {
            modelData.activate();
          }
        }
      }

      BarTooltip {
        anchorItem: trayItem
        anchorWindow: root.anchorWindow
        hovered: mouseArea.containsMouse
        text: modelData.tooltip || modelData.title || "Tray item"
      }
    }
  }
}
