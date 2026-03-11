import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../services"
import "." as LocalWidgets

Row {
  id: root
  spacing: 8
  anchors.verticalCenter: parent.verticalCenter
  property var anchorWindow: null

  Repeater {
    model: SystemTray.items

    delegate: Rectangle {
      id: trayItem
      width: 24
      height: 24
      radius: 6
      color: mouseArea.containsMouse ? Colors.highlightLight : "transparent"
      scale: mouseArea.containsMouse ? 1.08 : 1.0

      anchors.verticalCenter: parent.verticalCenter
      Behavior on color { ColorAnimation { duration: 160 } }
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      IconImage {
        anchors.centerIn: parent
        implicitWidth: 18
        implicitHeight: 18
        source: modelData.icon || ""

        // Fallback icon if none found
        Text {
          anchors.centerIn: parent
          text: "󰏘"
          color: Colors.textSecondary
          font.pixelSize: 14
          visible: parent.status !== IconImage.Ready
        }
      }

      MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
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

      LocalWidgets.BarTooltip {
        anchorItem: trayItem
        anchorWindow: root.anchorWindow
        hovered: mouseArea.containsMouse
        text: modelData.tooltip || modelData.title || "Tray item"
      }
    }
  }
}
