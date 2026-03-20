import QtQuick
import "../../../services"
import "../../../widgets" as SharedWidgets

Item {
  id: root
  implicitWidth: mainRow.width
  implicitHeight: mainRow.height
  property var anchorWindow: null
  property bool isActive: false
  signal statsClicked()

  SharedWidgets.Ref { service: SystemStatus }

  Row {
    id: mainRow
    spacing: Appearance.spacingS
    anchors.verticalCenter: parent.verticalCenter

    // CPU Pill
    SharedWidgets.BarPill {
      anchorWindow: root.anchorWindow
      isActive: root.isActive
      tooltipText: "CPU " + SystemStatus.cpuUsage + " • " + SystemStatus.cpuTemp
      anchors.verticalCenter: parent.verticalCenter
      onClicked: root.statsClicked()

      Row {
        spacing: Appearance.spacingSM
        Text {
          text: ""
          color: Colors.primary
          font.pixelSize: Appearance.fontSizeLarge
          font.family: Appearance.fontMono
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: "CPU " + SystemStatus.cpuUsage
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    // Memory Pill
    SharedWidgets.BarPill {
      anchorWindow: root.anchorWindow
      isActive: root.isActive
      tooltipText: "RAM " + SystemStatus.ramUsage + " • GPU " + SystemStatus.gpuUsage
      anchors.verticalCenter: parent.verticalCenter
      onClicked: root.statsClicked()

      Row {
        spacing: Appearance.spacingSM
        Text {
          text: ""
          color: Colors.accent
          font.pixelSize: Appearance.fontSizeLarge
          font.family: Appearance.fontMono
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: "RAM " + SystemStatus.ramUsage
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
