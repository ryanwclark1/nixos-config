import Quickshell
import Quickshell.Bluetooth
import QtQuick
import "../services"

PopupWindow {
  id: root
  implicitWidth: 300
  implicitHeight: 400

  Rectangle {
    anchors.fill: parent
    color: Colors.surface
    border.color: Colors.border
    border.width: 1
    radius: 6

    Item {
      id: header
      width: parent.width
      height: 40
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.margins: 12

      Text {
        text: "Bluetooth"
        color: Colors.fgMain
        font.pixelSize: 16
        font.weight: Font.Bold
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
      }

      Rectangle {
        width: 40
        height: 20
        radius: 10
        color: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Colors.primary : Colors.textDisabled
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 24

        MouseArea {
          anchors.fill: parent
          onClicked: {
            if (Bluetooth.defaultAdapter) {
              Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
            }
          }
        }
      }
    }

    Rectangle {
      id: divider
      width: parent.width - 24
      height: 1
      color: Colors.border
      anchors.top: header.bottom
      anchors.horizontalCenter: parent.horizontalCenter
    }

    ListView {
      id: deviceList
      width: parent.width - 24
      anchors.top: divider.bottom
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.topMargin: 10
      anchors.bottomMargin: 10
      clip: true
      spacing: 5

      model: Bluetooth.devices

      delegate: Rectangle {
        width: deviceList.width
        height: 44
        color: index % 2 == 0 ? Colors.highlight : Colors.surface
        radius: 4

        Text {
          text: modelData.name || modelData.address || "Unknown Device"
          color: Colors.fgMain
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: 10
          width: parent.width - 90
          elide: Text.ElideRight
        }

        Rectangle {
          width: 70
          height: 26
          radius: 4
          color: modelData.connected ? Colors.primary : Colors.highlightLight
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: parent.right
          anchors.rightMargin: 10

          Text {
            text: modelData.connected ? "Connected" : "Connect"
            color: Colors.text
            font.pixelSize: 11
            anchors.centerIn: parent
          }

          MouseArea {
            anchors.fill: parent
            onClicked: {
              if (modelData.connected) {
                modelData.disconnect()
              } else {
                modelData.connect()
              }
            }
          }
        }
      }
    }
  }
}
