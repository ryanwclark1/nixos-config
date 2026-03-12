import QtQuick
import "../services"
import "../widgets" as SharedWidgets

Item {
  id: root
  implicitWidth: mainRow.width
  implicitHeight: mainRow.height
  property var anchorWindow: null
  signal statsClicked()

  SharedWidgets.Ref { service: SystemStatus }

  Row {
    id: mainRow
    spacing: Colors.spacingS
    anchors.verticalCenter: parent.verticalCenter

    // CPU Pill
    Rectangle {
      id: cpuPill
      width: cpuRow.width + 16
      height: 28
      radius: height / 2
      color: Colors.bgWidget
      anchors.verticalCenter: parent.verticalCenter
      scale: cpuMouse.containsMouse ? 1.04 : 1.0

      Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

      Row {
        id: cpuRow
        spacing: 6
        anchors.centerIn: parent
        Text {
          text: ""
          color: Colors.primary
          font.pixelSize: Colors.fontSizeLarge
          font.family: Colors.fontMono
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: "CPU " + SystemStatus.cpuUsage
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      SharedWidgets.StateLayer {
        id: cpuStateLayer
        hovered: cpuMouse.containsMouse
        pressed: cpuMouse.pressed
        stateColor: Colors.primary
      }

      MouseArea {
        id: cpuMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => { cpuStateLayer.burst(mouse.x, mouse.y); root.statsClicked(); }
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
      color: Colors.bgWidget
      anchors.verticalCenter: parent.verticalCenter
      scale: ramMouse.containsMouse ? 1.04 : 1.0

      Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

      Row {
        id: ramRow
        spacing: 6
        anchors.centerIn: parent
        Text {
          text: ""
          color: Colors.accent
          font.pixelSize: Colors.fontSizeLarge
          font.family: Colors.fontMono
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: "RAM " + SystemStatus.ramUsage
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      SharedWidgets.StateLayer {
        id: ramStateLayer
        hovered: ramMouse.containsMouse
        pressed: ramMouse.pressed
        stateColor: Colors.primary
      }

      MouseArea {
        id: ramMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => { ramStateLayer.burst(mouse.x, mouse.y); root.statsClicked(); }
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
