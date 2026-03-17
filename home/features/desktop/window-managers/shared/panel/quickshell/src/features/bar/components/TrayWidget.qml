import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "."
import "../../../services"
import "../../../widgets"


Flow {
  id: root
  spacing: Math.max(2, itemSpacing)
  property bool vertical: false
  flow: vertical ? Flow.TopToBottom : Flow.LeftToRight
  property var anchorWindow: null
  property int itemSize: 24
  property int iconSize: 18
  property int itemSpacing: Colors.spacingS

  Repeater {
    model: SystemTray.items

    delegate: Rectangle {
      id: trayItem
      width: root.itemSize
      height: root.itemSize
      radius: Colors.radiusXXS
      color: "transparent"
      scale: mouseArea.containsMouse ? 1.08 : 1.0

      Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }

      Image {
        anchors.centerIn: parent
        width: Math.min(root.iconSize, root.itemSize)
        height: Math.min(root.iconSize, root.itemSize)
        source: Config.resolveIconSource(modelData.icon || "")
        sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
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
