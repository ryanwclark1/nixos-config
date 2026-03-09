import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
  id: root
  spacing: 8
  anchors.verticalCenter: parent.verticalCenter

  Repeater {
    model: SystemTray.items

    delegate: Rectangle {
      id: trayItem
      width: 24
      height: 24
      radius: 6
      color: mouseArea.containsMouse ? "#1affffff" : "transparent"
      
      anchors.verticalCenter: parent.verticalCenter

      IconImage {
        anchors.centerIn: parent
        implicitWidth: 18
        implicitHeight: 18
        source: modelData.icon || ""
        
        // Fallback icon if none found
        Text {
          anchors.centerIn: parent
          text: "󰏘"
          color: "#aaaaaa"
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
          if (mouse.button === Qt.RightButton || mouse.button === Qt.LeftButton) {
            // Open the context menu at the item's position
            if (modelData.menu) {
              modelData.menu.open(trayItem);
            } else {
              // Some items use activate() for left click
              modelData.activate();
            }
          }
        }
      }

      // Tooltip
      Rectangle {
        id: tooltip
        visible: mouseArea.containsMouse && (modelData.tooltip || "") !== ""
        z: 100
        
        // Position it below the bar (assuming bar is at top)
        parent: root.parent.parent // Go up to a stable coordinate space
        x: trayItem.mapToItem(parent, 0, 0).x - (width / 2) + (trayItem.width / 2)
        y: 35 

        width: tooltipText.implicitWidth + 16
        height: 24
        color: "#cc101014"
        border.color: "#33ffffff"
        border.width: 1
        radius: 6

        Text {
          id: tooltipText
          anchors.centerIn: parent
          text: modelData.tooltip || ""
          color: "#ffffff"
          font.pixelSize: 10
        }
      }
    }
  }
}
