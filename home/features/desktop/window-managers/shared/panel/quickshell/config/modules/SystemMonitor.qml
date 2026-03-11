import QtQuick
import "../services"
import "../widgets" as SharedWidgets

Item {
  id: root
  implicitWidth: mainRow.width
  implicitHeight: mainRow.height
  property var anchorWindow: null
  signal statsClicked()

  Component.onCompleted: SystemStatus.subscribe()
  Component.onDestruction: SystemStatus.unsubscribe()

  Row {
    id: mainRow
    spacing: 8
    anchors.verticalCenter: parent.verticalCenter

    // CPU Pill
    Rectangle {
      id: cpuPill
      width: cpuRow.width + 16
      height: 28
      radius: height / 2
      color: cpuMouse.containsMouse ? Colors.highlightLight : Colors.bgWidget
      anchors.verticalCenter: parent.verticalCenter
      scale: cpuMouse.containsMouse ? 1.04 : 1.0

      Behavior on color { ColorAnimation { duration: 160 } }
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

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

      MouseArea {
        id: cpuMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.statsClicked()
      }

      SharedWidgets.BarTooltip {
        anchorItem: cpuPill
        anchorWindow: root.anchorWindow
        hovered: cpuMouse.containsMouse
        text: "CPU " + SystemStatus.cpuUsage + " • " + SystemStatus.cpuTemp
      }
    }

    // Memory Pill
    Rectangle {
      id: ramPill
      width: ramRow.width + 16
      height: 28
      radius: height / 2
      color: ramMouse.containsMouse ? Colors.highlightLight : Colors.bgWidget
      anchors.verticalCenter: parent.verticalCenter
      scale: ramMouse.containsMouse ? 1.04 : 1.0

      Behavior on color { ColorAnimation { duration: 160 } }
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

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

      MouseArea {
        id: ramMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.statsClicked()
      }

      SharedWidgets.BarTooltip {
        anchorItem: ramPill
        anchorWindow: root.anchorWindow
        hovered: ramMouse.containsMouse
        text: "RAM " + SystemStatus.ramUsage + " • GPU " + SystemStatus.gpuUsage
      }
    }
  }
}
