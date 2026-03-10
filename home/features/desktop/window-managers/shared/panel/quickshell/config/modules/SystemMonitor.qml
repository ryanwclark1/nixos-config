import QtQuick
import "../services"

Item {
  id: root
  implicitWidth: mainRow.width
  implicitHeight: mainRow.height

  Row {
    id: mainRow
    spacing: 8
    anchors.verticalCenter: parent.verticalCenter

    // CPU Pill
    Rectangle {
      width: cpuRow.width + 16
      height: 28
      radius: height / 2
      color: Colors.bgWidget
      anchors.verticalCenter: parent.verticalCenter

      Row {
        id: cpuRow
        spacing: 6
        anchors.centerIn: parent
        Text {
          text: ""
          color: Colors.primary
          font.pixelSize: 16
          font.family: Colors.fontMono
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: "CPU " + SystemStatus.cpuUsage
          color: Colors.fgMain
          font.pixelSize: 13
          font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    // Memory Pill
    Rectangle {
      width: ramRow.width + 16
      height: 28
      radius: height / 2
      color: Colors.bgWidget
      anchors.verticalCenter: parent.verticalCenter

      Row {
        id: ramRow
        spacing: 6
        anchors.centerIn: parent
        Text {
          text: ""
          color: Colors.accent
          font.pixelSize: 16
          font.family: Colors.fontMono
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: "RAM " + SystemStatus.ramUsage
          color: Colors.fgMain
          font.pixelSize: 13
          font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
